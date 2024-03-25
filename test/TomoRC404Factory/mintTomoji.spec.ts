
import { expect } from 'chai';
import {
    makeSuiteCleanRoom,
    user,
    userAddress,
    owner,
    tomojiFactory,
    ownerAddress,
    userTwoAddress,
    tomojiManagerAddr,
} from '../__setup.spec';
import { Tomoji__factory } from '../../typechain-types';
import { ethers } from 'hardhat';
import { ERRORS } from '../helpers/errors';
import { BigNumber, BigNumberish } from '@ethersproject/bignumber'

import bn from 'bignumber.js'
import { buildMintSeparator } from '../helpers/utils';

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

makeSuiteCleanRoom('Mint ERC404', function () {

    const mintPrice = ethers.parseEther("0.01");
    const sqrtPriceX96 = encodePriceSqrt(ethers.parseEther("0.01"), ethers.parseEther("1"));
    const sqrtPriceB96 = encodePriceSqrt(ethers.parseEther("1"), ethers.parseEther("0.01"));
    let tomoErc404Address: string
    let nftTotalSupply = 10000
    let reserved0 = 0
    let reserved1 = 1000
    let maxPerWallet = 200
    let units = 1
    let price0 = 0
    let price1 = ethers.parseEther("0.2")
    let name = "Tomo-emoji"
    let symbol = "Tomo-emoji"
    let baseUri = "https://tomo-baseuri/"
    let contractUri = "https://tomo-contract"   
    const tomorrow = parseInt((new Date().getTime() / 1000 ).toFixed(0)) + 24 * 3600
    const TOMOJI_NAME = 'Tomoji'

    context('Generic', function () {
        beforeEach(async function () {
            
            await expect(tomojiFactory.connect(owner).createTomoji({
                    creator: ownerAddress, 
                    nftTotalSupply: nftTotalSupply,
                    reserved: reserved1,
                    maxPerWallet: maxPerWallet,
                    price: mintPrice,
                    preSaleDeadLine: tomorrow,
                    sqrtPriceX96: sqrtPriceX96.toBigInt(),
                    sqrtPriceB96: sqrtPriceB96.toBigInt(),
                    bSupportEOAMint: true,
                    name: name, 
                    symbol: symbol, 
                    baseURI: baseUri, 
                    contractURI: contractUri
                }, {value: ethers.parseEther("15")})
            ).to.be.not.reverted;
            tomoErc404Address = await tomojiFactory.connect(owner)._erc404Contract(ownerAddress, name);

            let brc404Contract = Tomoji__factory.connect(tomoErc404Address, user);
            expect(await brc404Contract.balanceOf(tomojiManagerAddr)).to.equal(ethers.parseEther(((nftTotalSupply - reserved1)).toString()));
        });

        context('Negatives', function () {
            it('Mint failed if mint amount is 0.',   async function () {
                const sig = await buildMintSeparator(tomoErc404Address, TOMOJI_NAME, tomoErc404Address, userAddress, 0);

                let brc404Contract = Tomoji__factory.connect(tomoErc404Address, user);
                await expect(brc404Contract.mint(0, sig.v, sig.r, sig.s)).to.be.revertedWithCustomError(brc404Contract, ERRORS.InvaildParam)
            });
            it('Mint failed if msg.valur less than you need to pay.',   async function () {
                const sig = await buildMintSeparator(tomoErc404Address, TOMOJI_NAME, tomoErc404Address, userAddress, 2);
                let brc404Contract = Tomoji__factory.connect(tomoErc404Address, user);
                await expect(brc404Contract.mint(2, sig.v, sig.r, sig.s, {
                    value: ethers.parseEther("0.01")
                })).to.be.revertedWithCustomError(brc404Contract, ERRORS.InvaildParam)
            });
            it('Mint failed if mint amount ReachMaxPerMint.',   async function () {
                const sig = await buildMintSeparator(tomoErc404Address, TOMOJI_NAME, tomoErc404Address, userAddress, 201);
                let brc404Contract = Tomoji__factory.connect(tomoErc404Address, user);
                await expect(brc404Contract.mint(201, sig.v, sig.r, sig.s, {
                    value: ethers.parseEther("200")
                })).to.be.revertedWithCustomError(brc404Contract, ERRORS.ReachMaxPerMint)
            });
        })

        context('Scenarios', function () {
            it('Get correct variable if mint Tomo-emoji success.',   async function () {
                const sig = await buildMintSeparator(tomoErc404Address, TOMOJI_NAME, tomoErc404Address, userAddress, 2);
                let brc404Contract = Tomoji__factory.connect(tomoErc404Address, user);
                await expect(brc404Contract.mint(2, sig.v, sig.r, sig.s, {
                    value: ethers.parseEther("0.4")
                })).to.not.be.reverted;
                
                expect( await brc404Contract.balanceOf(userAddress)).to.equal(ethers.parseEther("2"));
                expect( await brc404Contract.erc721BalanceOf(userAddress)).to.equal(2);
                expect( await brc404Contract.ownerOf(1)).to.equal(userAddress);
                expect( await brc404Contract.ownerOf(2)).to.equal(userAddress);
                await expect(brc404Contract.transfer(userTwoAddress, 
                    ethers.parseEther("0.4")
                )).to.be.revertedWithCustomError(brc404Contract, ERRORS.TradingNotEnable)
                // expect( await brc404Contract.ownerOf(1)).to.equal(userAddress);
                // const arr = await brc404Contract.connect(user).getERC721TokensInQueue(0,1)
                // expect(arr[0]).to.equal(2)
                // await expect(brc404Contract.transfer(userTwoAddress, 
                //     ethers.parseEther("0.7")
                // )).to.not.be.reverted;
                // expect( await brc404Contract.ownerOf(2)).to.equal(userTwoAddress);
                // const arr1 = await brc404Contract.connect(user).getERC721TokensInQueue(0,1)
                // expect(arr1[0]).to.equal(1)
            });
        })
    })
})