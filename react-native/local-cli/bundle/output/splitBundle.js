/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */
'use strict';

const Promise = require('promise');
const mkdirp = require('mkdirp');
const path = require('path');

const {combineSourceMaps, joinModules} = require('./unbundle/util');
const writeSourceMap = require('./unbundle/write-sourcemap');
const writeFile = require('./writeFile');

const MODULES_DIR = 'bundles';

const newline = /\r\n?|\n|\u2028|\u2029/g;
const countLines =
  string => (string.match(newline) || []).length + 1; // fastest implementation

const buildSourceMapWithMetaData = ({startupModules, lazyModules}) => {
  const startupModule = {
    code: joinModules(startupModules),
    map: combineSourceMaps({modules: startupModules}),
  };
  const map = combineSourceMaps({
    modules: [startupModule].concat(lazyModules),
  });
  // map.ff_bundle_offset = {};
  return map;
};


function buildBundle(packagerClient, requestOptions) {
  return packagerClient.buildBundle({
    ...requestOptions,
    isolateModuleIDs: true,
  });
}

function saveBundleAndMap(bundle, options, log) {
  // console.log('save')
  // process.exit()
  const {
    bundleOutput,
    bundleEncoding: encoding,
    dev,
    sourcemapOutput
  } = options;

  log('start');
  const {startupModules, lazyModulesByBundle, dependencyInfo} = bundle.getSplitBundle();
  console.log(dependencyInfo)
  log('finish');
  const startupCode = joinModules(startupModules);

  log('Writing bundle output to:', bundleOutput);
  const modulesDir = path.join(path.dirname(bundleOutput), MODULES_DIR);
  const writeUnbundle =
    createDir(modulesDir).then( // create the modules directory first
      () => Promise.all([
        writeBundles(lazyModulesByBundle, modulesDir, encoding),
        writeFile(bundleOutput, startupCode, encoding),
      ])
    );
  writeUnbundle.then(() => log('Done writing split bundle output'));

  const sourceMap =
    buildSourceMapWithMetaData({
      startupModules,
      lazyModules: Array.prototype.concat.apply(
        [],
        Object.keys(lazyModulesByBundle).map(k => lazyModulesByBundle[k]))
    });

  // const writeBundleInfo = 

  return Promise.all([
    writeUnbundle,
    // writeBundleInfo,
    writeSourceMap(sourcemapOutput, JSON.stringify(sourceMap), log)
  ]);
}

function createDir(dirName) {
  return new Promise((resolve, reject) =>
    mkdirp(dirName, error => error ? reject(error) : resolve()));
}

function writeBundleFile(bundleName, modules, modulesDir, encoding) {
  return writeFile(path.join(modulesDir, bundleName + '.js'), joinModules(modules), encoding);
}

function writeBundles(bundles, modulesDir, encoding) {
  const writeFiles =
    Object.keys(bundles).map(
      bundleName => writeBundleFile(bundleName, bundles[bundleName], modulesDir, encoding));
  return Promise.all(writeFiles);
}

exports.build = buildBundle;
exports.save = saveBundleAndMap;
exports.formatName = 'splitBundle';
