const { expect } = require("chai");
const { ethers } = require("hardhat");
const keccak256 = require("keccak256");
//const SHA256 = require('crypto-js/sha256')
const { MerkleTree } = require('merkletreejs')

describe("NFT With Whitelist Tests", function () {
  let addrObjects;
  let addresses;
  let nft;
  let leaves;
  let tree;
  let root;
  let lastAddress;
  beforeEach(async function(){
    
    addrObjects = await ethers.getSigners();
    lastAddress = addrObjects[addrObjects.length -1];
    addrObjects = addrObjects.splice(0,8);
    const NFTWhitelist = await ethers.getContractFactory("NFTWhitelist");
    
    nft = await NFTWhitelist.deploy();
    await nft.deployed();
    addrObjects = Array.from(addrObjects);
    addresses = addrObjects.map(x => x.address);
    leaves = addresses.map(x => keccak256(x));
    tree = new MerkleTree(leaves, keccak256, { sort: true })
    root = tree.getHexRoot()
    let tx = await nft.setWhitelistRoot(root);
    
    if(tx?.wait) await tx.wait();
    
  })

  it("Should revert when whitelist sale is not active", async function () {
    let proof = tree.getHexProof(keccak256(addresses[0]));
    await expect(nft.connect(addrObjects[0]).whitelistMint(proof,1)).to.be.revertedWith("Whitelist Sale is not active");
  });

  it("Should be able to set status of contract whitelist", async function () {
    await expect(await nft.setStatus(1))
  });

  it("Whitelist should be able to mint 2 nft", async function () {
    let proof = tree.getHexProof(keccak256(addresses[1]));
    let tx = await nft.setStatus(1);
    tx?.wait && tx.wait();
    let amount = 2;
    let price = 0.75*amount;
    await expect(nft.connect(addrObjects[1]).whitelistMint(proof, amount,{
      value:ethers.utils.parseEther(price.toString())
    }));
  });

  it("Whitelist users cant mint more then 2", async function () {
    let proof = tree.getHexProof(keccak256(addresses[1]));
    let tx = await nft.setStatus(1);
    tx?.wait && tx.wait();
    await expect(nft.connect(addrObjects[1]).whitelistMint(proof, 3,{
      value:ethers.utils.parseEther("3.0")
    })).to.be.revertedWith("NFTWhitelist: You can't mint more then 2");
  });

  it("None whitelisted user can't mint if not verified", async function () {
    let proof = tree.getHexProof(keccak256(lastAddress.address));
    let tx = await nft.setStatus(1);
    tx?.wait && tx.wait();
    await expect(nft.connect(lastAddress).whitelistMint(proof, 1,{
      value:ethers.utils.parseEther("1.0")
    })).to.be.revertedWith("NFTWhitelist : This address is not whitelisted");
  });

});
