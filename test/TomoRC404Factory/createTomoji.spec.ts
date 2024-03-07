
import {
    makeSuiteCleanRoom, owner, tomojiFactory,ownerAddress, user
} from '../__setup.spec';
import { expect } from 'chai';
import { ERRORS } from '../helpers/errors';
import { findEvent, waitForTx } from '../helpers/utils';
import { Tomoji__factory } from '../../typechain-types';
import { ethers } from 'hardhat';

makeSuiteCleanRoom('create ERC404', function () {
    context('Generic', function () {
        context('Negatives', function () {
            it('User should fail to create if reserved large than supply.',   async function () {
                await expect(tomojiFactory.connect(owner).createERC404({
                    creator: ownerAddress, 
                    nftTotalSupply: 10000,
                    reserved: 10001,
                    maxPerWallet: 100,
                    units: 100,
                    price: 10000,
                    name: "MoMo", 
                    symbol: "Momo", 
                    baseURI: "https://tomo-baseuri/", 
                    contractURI: "https://tomo-contract"
                })).to.be.revertedWithCustomError(tomojiFactory, ERRORS.ReservedTooMuch)
            });

            it('User should fail to create twice using same param.',   async function () {
                await expect(tomojiFactory.connect(owner).createERC404({
                    creator: ownerAddress, 
                    nftTotalSupply: 10000,
                    reserved: 0,
                    maxPerWallet: 100,
                    units: 100,
                    price: 10000,
                    name: "MoMo", 
                    symbol: "Momo", 
                    baseURI: "https://tomo-baseuri/", 
                    contractURI: "https://tomo-contract"
                })).to.not.be.reverted;
                await expect(tomojiFactory.connect(owner).createERC404({
                    creator: ownerAddress, 
                    nftTotalSupply: 10000,
                    reserved: 0,
                    maxPerWallet: 100,
                    units: 100,
                    price: 10000,
                    name: "MoMo", 
                    symbol: "Momo", 
                    baseURI: "https://tomo-baseuri/", 
                    contractURI: "https://tomo-contract"
                })).to.be.revertedWithCustomError(tomojiFactory, ERRORS.ContractAlreadyExist);
            });
        })

        context('Scenarios', function () {
            it('Create tomo emoji collection if pass correct param.',   async function () {
                await expect(tomojiFactory.connect(owner).createERC404({
                    creator: ownerAddress, 
                    nftTotalSupply: 10000,
                    reserved: 100,
                    maxPerWallet: 100,
                    units: 100,
                    price: 10000,
                    name: "MoMo", 
                    symbol: "Momo", 
                    baseURI: "https://tomo-baseuri/", 
                    contractURI: "https://tomo-contract"
                })).to.not.be.reverted;
            })
            it('Get correct variable tomo emoji collection if pass correct param.',   async function () {
                let tomoErc404Address: string
                let nftTotalSupply = 10000
                let reserved0 = 0
                let reserved1 = 2000
                let maxPerWallet = 200
                let units = 200
                let price0 = 0
                let price1 = 10000
                let name = "Tomo-emoji"
                let symbol = "Tomo-emoji"
                let baseUri = "https://tomo-baseuri/"
                let contractUri = "https://tomo-contract"
                
                const receipt = await waitForTx(
                    tomojiFactory.connect(owner).createERC404({
                        creator: ownerAddress, 
                        nftTotalSupply: nftTotalSupply,
                        reserved: reserved1,
                        maxPerWallet: maxPerWallet,
                        units: units,
                        price: price1,
                        name: name, 
                        symbol: symbol, 
                        baseURI: baseUri, 
                        contractURI: contractUri
                    })
                );
                expect(receipt.logs.length).to.eq(5, `Expected 1 events, got ${receipt.logs.length}`);
                const event = findEvent(receipt, 'ERC404Created');
                tomoErc404Address = event!.args[0];
                console.log(tomoErc404Address)
    
                let brc404Contract = Tomoji__factory.connect(tomoErc404Address, user);
                expect(await brc404Contract.units()).to.equal(ethers.parseEther("200"));
                expect(await brc404Contract.balanceOf(tomoErc404Address)).to.equal(ethers.parseEther(((nftTotalSupply-reserved1)*units).toString()));
                expect(await brc404Contract.balanceOf(ownerAddress)).to.equal(ethers.parseEther(((reserved1)*units).toString()));
            })
        })
    })
})