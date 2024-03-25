
import {
    makeSuiteCleanRoom, owner, tomojiFactory,ownerAddress, user, tomojiManager, tomojiManagerAddr
} from '../__setup.spec';
import { expect } from 'chai';
import { ERRORS } from '../helpers/errors';
import { Tomoji__factory } from '../../typechain-types';
import { ethers } from 'hardhat';
import { BigNumber, BigNumberish } from '@ethersproject/bignumber'

import bn from 'bignumber.js'
bn.config({ EXPONENTIAL_AT: 999999, DECIMAL_PLACES: 40 })
// returns the sqrt price as a 64x96
function encodePriceSqrt(reserve1: BigNumberish, reserve0: BigNumberish): BigNumber {
  return BigNumber.from(
    new bn(reserve1.toString())
      .div(reserve0.toString())
      .sqrt()
      .multipliedBy(new bn(2).pow(96))
      .integerValue(3)
      .toString()
  )
}

const tomorrow = parseInt((new Date().getTime() / 1000 ).toFixed(0)) + 24 * 3600

makeSuiteCleanRoom('create ERC404', function () {
    const mintPrice = ethers.parseEther("0.01");
    const sqrtPriceX96 = encodePriceSqrt(ethers.parseEther("0.01"), ethers.parseEther("1"));
    const sqrtPriceB96 = encodePriceSqrt(ethers.parseEther("1"), ethers.parseEther("0.01"));
    context('Generic', function () {
        context('Negatives', function () {
            it('User should fail to create if reserved large than supply.',   async function () {
                
                await expect(tomojiFactory.connect(owner).createTomoji({
                    creator: ownerAddress, 
                    nftTotalSupply: 10000,
                    reserved: 10001,
                    maxPerWallet: 100,
                    price: mintPrice,
                    preSaleDeadLine: tomorrow,
                    sqrtPriceX96: sqrtPriceX96.toBigInt(),
                    sqrtPriceB96: sqrtPriceB96.toBigInt(),
                    name: "MoMo", 
                    symbol: "Momo", 
                    baseURI: "https://tomo-baseuri/", 
                    contractURI: "https://tomo-contract"
                })).to.be.revertedWithCustomError(tomojiFactory, ERRORS.ReservedTooMuch)
            });

            it('User should fail to create twice using same param.',   async function () {
                await expect(tomojiFactory.connect(owner).createTomoji({
                    creator: ownerAddress, 
                    nftTotalSupply: 10000,
                    reserved: 0,
                    maxPerWallet: 100,
                    price: mintPrice,
                    preSaleDeadLine: tomorrow,
                    sqrtPriceX96: sqrtPriceX96.toBigInt(),
                    sqrtPriceB96: sqrtPriceB96.toBigInt(),
                    name: "MoMo", 
                    symbol: "Momo", 
                    baseURI: "https://tomo-baseuri/", 
                    contractURI: "https://tomo-contract"
                })).to.be.not.reverted;
                await expect(tomojiFactory.connect(owner).createTomoji({
                    creator: ownerAddress, 
                    nftTotalSupply: 10000,
                    reserved: 0,
                    maxPerWallet: 100,
                    price: mintPrice,
                    preSaleDeadLine: tomorrow,
                    sqrtPriceX96: sqrtPriceX96.toBigInt(),
                    sqrtPriceB96: sqrtPriceB96.toBigInt(),
                    name: "MoMo", 
                    symbol: "Momo", 
                    baseURI: "https://tomo-baseuri/", 
                    contractURI: "https://tomo-contract"
                })).to.be.revertedWithCustomError(tomojiFactory, ERRORS.ContractAlreadyExist);
            });
        })

        context('Scenarios', function () {
            it('Create tomo emoji collection if pass correct param.',   async function () {
                await expect(tomojiFactory.connect(owner).createTomoji({
                    creator: ownerAddress, 
                    nftTotalSupply: 10000,
                    reserved: 100,
                    maxPerWallet: 100,
                    price: mintPrice,
                    preSaleDeadLine: tomorrow,
                    sqrtPriceX96: sqrtPriceX96.toBigInt(),
                    sqrtPriceB96: sqrtPriceB96.toBigInt(),
                    name: "MoMo", 
                    symbol: "Momo", 
                    baseURI: "https://tomo-baseuri/", 
                    contractURI: "https://tomo-contract"
                }, {value: ethers.parseEther("1")})).to.not.be.reverted;
            })
            it('Get correct variable tomo emoji collection if pass correct param.',   async function () {
                
                let tomoErc404Address: string
                let nftTotalSupply = 10000
                let reserved0 = 0
                let reserved1 = 1000
                let maxPerWallet = 200
                let price0 = 0
                let price1 = mintPrice
                let name = "Tomo-emoji"
                let symbol = "Tomo-emoji"
                let baseUri = "https://tomo-baseuri/"
                let contractUri = "https://tomo-contract"
                
                await expect(tomojiFactory.connect(owner).createTomoji({
                        creator: ownerAddress, 
                        nftTotalSupply: nftTotalSupply,
                        reserved: reserved1,
                        maxPerWallet: maxPerWallet,
                        price: mintPrice,
                        preSaleDeadLine: tomorrow,
                        sqrtPriceX96: sqrtPriceX96.toBigInt(),
                        sqrtPriceB96: sqrtPriceB96.toBigInt(),
                        name: name, 
                        symbol: symbol, 
                        baseURI: baseUri, 
                        contractURI: contractUri
                    }, {value: ethers.parseEther("15")})
                ).to.not.be.reverted;

                tomoErc404Address = await tomojiFactory.connect(owner)._erc404Contract(ownerAddress, name);
    
                let brc404Contract = Tomoji__factory.connect(tomoErc404Address, user);
                expect(await brc404Contract.balanceOf(tomojiManagerAddr)).to.equal(ethers.parseEther(((nftTotalSupply-reserved1)).toString()));
                expect(await brc404Contract.balanceOf(ownerAddress)).to.equal(ethers.parseEther(((reserved1)).toString()));

                expect(await ethers.provider.getBalance(tomoErc404Address)).to.equal(ethers.parseEther("10"));
            })
        })
    })
})