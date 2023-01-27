const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BloomThis", function () {
  it("BloomThis -1", async function () {
    const [owner, addr1, addr2, addr3] = await ethers.getSigners();

    console.log(addr1.address);
    console.log(addr2.address);
    console.log(addr3.address);
    console.log("owner balance", await ethers.provider.getBalance(owner.address));
    console.log("addr1 balance", await ethers.provider.getBalance(owner.address));

    const BloomThis = await ethers.getContractFactory("BloomThis");
    const _BloomThis = await BloomThis.deploy("BLOOM", "BLOM", true, 1402);
    await _BloomThis.deployed();

    await _BloomThis.mint(addr1.address, "https://somelink.com", 1);
    await _BloomThis.mint(addr1.address, "https://somelink.com", 1);
    await _BloomThis.mint(addr1.address, "https://somelink.com", 1);

    console.log("_BloomThis pending reward", await _BloomThis._pendingReward());

    let addr1Balance = await ethers.provider.getBalance(addr1.address);
    console.log("addr1 balance change", await ethers.provider.getBalance(addr1.address));

    await owner.sendTransaction({
      to: _BloomThis.address,
      value: ethers.utils.parseEther("3.0"), // Sends exactly 1.0 ether
      gasLimit: 21000000,
    });

    console.log("_BloomThis pending reward", await _BloomThis._pendingReward());
    await _BloomThis.connect(addr1).claimRewards();

    console.log("addr1 balance change", await ethers.provider.getBalance(addr1.address));

    console.log("_BloomThis pending reward", await _BloomThis._pendingReward());

    await _BloomThis.mint(addr1.address, "https://somelink.com", 1);
    await _BloomThis.mint(addr1.address, "https://somelink.com", 1);
    await _BloomThis.mint(addr1.address, "https://somelink.com", 1);

    await _BloomThis.mint(addr1.address, "https://somelink.com", 2);
    await _BloomThis.mint(addr1.address, "https://somelink.com", 2);
    await _BloomThis.mint(addr1.address, "https://somelink.com", 2);

    await _BloomThis.mint(addr1.address, "https://somelink.com", 2);
    await _BloomThis.mint(addr2.address, "https://somelink.com", 2);
    await _BloomThis.mint(addr3.address, "https://somelink.com", 2);

    await _BloomThis.addFusionUris(5, ["https://somelink.com", "https://somelink.com", "https://somelink.com", "https://somelink.com", "https://somelink.com"]);
    await _BloomThis.addFusionUris(6, ["https://somelink.com", "https://somelink.com", "https://somelink.com", "https://somelink.com", "https://somelink.com"]);
    await _BloomThis.addFusionUris(7, ["https://somelink.com", "https://somelink.com", "https://somelink.com", "https://somelink.com", "https://somelink.com"]);

    console.log("5 balance", await _BloomThis.connect(owner).getFusionUrisBalance(5));
    console.log("6 balance", await _BloomThis.connect(owner).getFusionUrisBalance(6));
    console.log("7 balance", await _BloomThis.connect(owner).getFusionUrisBalance(7));

    await _BloomThis.addFusionRule(1, [7, 2, 1]);
    await _BloomThis.addFusionRule(2, [6, 1, 2]);

    await _BloomThis.connect(addr1).doFusion(1, [1, 2, 7]);
    return;

    console.log("5 balance", await _BloomThis.connect(owner).getFusionUrisBalance(5));
  });
});
