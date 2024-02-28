import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import {
    makeSuiteCleanRoom,
    user,
    userAddress,
    owner,
    tomoErc404Factory,
    ownerAddress,
} from '../__setup.spec';
import {
    findEvent, waitForTx 
  } from '../helpers/utils';
import { TomoERC404__factory } from '../../typechain-types';

makeSuiteCleanRoom('Mint BRC404', function () {

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

    context('Generic', function () {
        beforeEach(async function () {
            const receipt = await waitForTx(
                tomoErc404Factory.connect(owner).createERC404({
                    creator: ownerAddress, 
                    nftTotalSupply: nftTotalSupply,
                    reserved: reserved0,
                    maxPerWallet: maxPerWallet,
                    units: units,
                    price: price0,
                    name: name, 
                    symbol: symbol, 
                    baseURI: baseUri, 
                    contractURI: contractUri
                })
            );
            expect(receipt.logs.length).to.eq(5, `Expected 1 events, got ${receipt.logs.length}`);
            const event = findEvent(receipt, 'ERC404Created');
            tomoErc404Address = event.args[0];

            let brc404Contract = TomoERC404__factory.connect(tomoErc404Address, user);
            expect(await brc404Contract.units()).to.equal(200);
        });

        context('Negatives', function () {

        })

        context('Scenarios', function () {
            it('Get correct variable if mint Tomo-emoji success.',   async function () {

                let brc404Contract = TomoERC404__factory.connect(tomoErc404Address, user);
                await expect(brc404Contract.mint(1)).to.not.be.reverted;

                expect( await brc404Contract.balanceOf(userAddress)).to.equal(200);
                expect( await brc404Contract.erc721BalanceOf(userAddress)).to.equal(1);
                expect( await brc404Contract.ownerOf(1)).to.equal(userAddress);
            });
        })
    })
})