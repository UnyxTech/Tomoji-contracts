
import { expect } from 'chai';
import {
    makeSuiteCleanRoom,
    user,
    userAddress,
    owner,
    tomojiFactory,
    ownerAddress,
    userTwoAddress,
} from '../__setup.spec';
import {
    findEvent, waitForTx 
  } from '../helpers/utils';
import { Tomoji__factory } from '../../typechain-types';
import { ethers } from 'hardhat';
import { ERRORS } from '../helpers/errors';

makeSuiteCleanRoom('Mint ERC404', function () {

    let tomoErc404Address: string
    let nftTotalSupply = 10000
    let reserved0 = 0
    let reserved1 = 9900
    let maxPerWallet = 200
    let units = 1
    let price0 = 0
    let price1 = ethers.parseEther("0.2")
    let name = "Tomo-emoji"
    let symbol = "Tomo-emoji"
    let baseUri = "https://tomo-baseuri/"
    let contractUri = "https://tomo-contract"

    context('Generic', function () {
        beforeEach(async function () {
            const receipt = await waitForTx(
                tomojiFactory.connect(owner).createERC404({
                    creator: ownerAddress, 
                    nftTotalSupply: nftTotalSupply,
                    reserved: reserved1,
                    maxPerWallet: maxPerWallet,
                    price: price1,
                    name: name, 
                    symbol: symbol, 
                    baseURI: baseUri, 
                    contractURI: contractUri
                })
            );
            expect(receipt.logs.length).to.eq(5, `Expected 4 events, got ${receipt.logs.length}`);
            const event = findEvent(receipt, 'ERC404Created');
            tomoErc404Address = event!.args[0];

            let brc404Contract = Tomoji__factory.connect(tomoErc404Address, user);
            expect(await brc404Contract.units()).to.equal(ethers.parseEther("1"));
            expect(await brc404Contract.balanceOf(tomoErc404Address)).to.equal(ethers.parseEther(((nftTotalSupply - reserved1)).toString()));
        });

        context('Negatives', function () {
            it('Mint failed if mint amount is 0.',   async function () {
                let brc404Contract = Tomoji__factory.connect(tomoErc404Address, user);
                await expect(brc404Contract.mint(0)).to.be.revertedWithCustomError(brc404Contract, ERRORS.InvaildParam)
            });
            it('Mint failed if msg.valur less than you need to pay.',   async function () {
                let brc404Contract = Tomoji__factory.connect(tomoErc404Address, user);
                await expect(brc404Contract.mint(2, {
                    value: ethers.parseEther("0.1")
                })).to.be.revertedWithCustomError(brc404Contract, ERRORS.InvaildParam)
            });
            it('Mint failed if mint amount ReachMaxPerMint.',   async function () {
                let brc404Contract = Tomoji__factory.connect(tomoErc404Address, user);
                await expect(brc404Contract.mint(201, {
                    value: ethers.parseEther("200")
                })).to.be.revertedWithCustomError(brc404Contract, ERRORS.ReachMaxPerMint)
            });
            it('Mint failed if not enough.',   async function () {
                let brc404Contract = Tomoji__factory.connect(tomoErc404Address, user);
                await expect(brc404Contract.mint(101, {
                    value: ethers.parseEther("200")
                })).to.be.revertedWithCustomError(brc404Contract, ERRORS.NotEnough)
            });
        })

        context('Scenarios', function () {
            it('Get correct variable if mint Tomo-emoji success.',   async function () {
                let brc404Contract = Tomoji__factory.connect(tomoErc404Address, user);
                await expect(brc404Contract.mint(2, {
                    value: ethers.parseEther("0.4")
                })).to.not.be.reverted;
                expect( await brc404Contract.balanceOf(userAddress)).to.equal(ethers.parseEther("2"));
                expect( await brc404Contract.erc721BalanceOf(userAddress)).to.equal(2);
                expect( await brc404Contract.ownerOf(1)).to.equal(userAddress);
                expect( await brc404Contract.ownerOf(2)).to.equal(userAddress);
                await expect(brc404Contract.transfer(userTwoAddress, 
                    ethers.parseEther("0.4")
                )).to.not.be.reverted;
                expect( await brc404Contract.ownerOf(1)).to.equal(userAddress);
                const arr = await brc404Contract.connect(user).getERC721TokensInQueue(0,1)
                expect(arr[0]).to.equal(2)
                await expect(brc404Contract.transfer(userTwoAddress, 
                    ethers.parseEther("0.7")
                )).to.not.be.reverted;
                expect( await brc404Contract.ownerOf(2)).to.equal(userTwoAddress);
                const arr1 = await brc404Contract.connect(user).getERC721TokensInQueue(0,1)
                expect(arr1[0]).to.equal(1)
            });
        })
    })
})