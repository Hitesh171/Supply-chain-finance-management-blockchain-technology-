const SupplyChainFinance = artifacts.require("SupplyChainFinance");

module.exports = function (deployer) {
  deployer.deploy(SupplyChainFinance);
};
