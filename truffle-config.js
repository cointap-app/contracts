var HDWalletProvider = require("truffle-hdwallet-provider");

module.exports = {
  // Uncommenting the defaults below 
  // provides for an easier quick-start with Ganache.
  // You can also follow this format for other networks;
  // see <http://truffleframework.com/docs/advanced/configuration>
  // for more details on how to specify configuration options!
  //
  networks: {
    // development: {
    //   host: "127.0.0.1",
    //   port: 7545,
    //   network_id: "*"
    // },
    // test: {
    //   host: "127.0.0.1",
    //   port: 7545,
    //   network_id: "*"
    // },
    bscTestnet: {
      host: "https://data-seed-prebsc-1-s1.binance.org",
      port: 8545,
      network_id: "97",
      provider: () => new HDWalletProvider(["privatekey"], "https://data-seed-prebsc-1-s1.binance.org:8545"),
    },
  },
  compilers: {
    solc: {
      version: "0.8.7",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200   // Optimize for how many times you intend to run the code
        },
      },
    }
  },
  plugins: [
    'truffle-plugin-verify'
  ],
  api_keys: {
    bscscan: 'I2K9IIDIXVW8BM5IR3NW5WPAM8BIRC4KPF',
    etherscan: '',
    polygonscan: 'PY1HE7T1I1WDX2YBEXZV7FQRTS62QF957K',
    hecoinfo: '',
    ftmscan: '',
  }
  //
  // Truffle DB is currently disabled by default; to enable it, change enabled:
  // false to enabled: true. The default storage location can also be
  // overridden by specifying the adapter settings, as shown in the commented code below.
  //
  // NOTE: It is not possible to migrate your contracts to truffle DB and you should
  // make a backup of your artifacts to a safe location before enabling this feature.
  //
  // After you backed up your artifacts you can utilize db by running migrate as follows: 
  // $ truffle migrate --reset --compile-all
  //
  // db: {
  // enabled: false,
  // host: "127.0.0.1",
  // adapter: {
  //   name: "sqlite",
  //   settings: {
  //     directory: ".db"
  //   }
  // }
  // }
};
