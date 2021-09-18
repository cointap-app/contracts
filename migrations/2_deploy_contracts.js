const CoinTapMultiSender = artifacts.require("CoinTapMultiSender");

module.exports = function(deployer) {
  deployer.deploy(CoinTapMultiSender);
};
