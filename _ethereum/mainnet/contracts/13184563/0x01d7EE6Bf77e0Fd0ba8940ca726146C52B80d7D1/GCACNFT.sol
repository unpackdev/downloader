// SPDX-License-Identifier: UNLICENSED
/*
* https://cannappscorp.com/ -- Global Cannabis Applications Corporation (GCAC)
*
* Address: Suite 830, 1100 Melville Street, Vancouver, British Columbia, V6E 4A6 Canada
* Email: info@cannappscorp.com
*
* As at 31-August-2021, GCAC is a publicly traded company on the Canadian Stock Exchange.
*
* Official GCAC Listing
* https://www.thecse.com/en/listings/technology/global-cannabis-applications-corp
*
* Official GCAC Regulatory Filings 
* https://www.sedar.com/DisplayCompanyDocuments.do?lang=EN&issuerNo=00036309
*
* This is an ERC-721 NFT smart contract for the first GCAC NFT containing 741 unique tokens
* that may be used in any/all future metaverses based on the Ethereum blockchain. 
*
* This GCAC NFT has the following traits which have a varying set of color rarities:
*  "Bottle"
*  "Phone"
*  "Screen"
*  "Background"
*  "Block"
*  "Label"
*
* Who knows, a holder of a GCAC NFT with a Brown "Bottle" may be able to get the best
* medical cannabis to use as a healing method .. only time and the metaverse will tell!
*
* 1. The number of GCAC NFTs from this contract shall be seven hundred and forty one (741).
* 2. One (1) NFT with a "Myhtic" rarity was awarded to our competition winner.
* 3. Twenty (20) NFTs with a "Legendary" rarity were awarded to our top 20 GCAC ERC-20 
*    hodlers on 31-August-2021 0900 ET.
* 4. Three hundred and seventeen (317) NFTs with a "Common" rarity were awarded to 
*    all other GCAC ERC-20 token hodlers on 31-August-2021 0900 ET.
* 5. The remaining four hundred and two (402) GCAC NFTs are avaiable to purchase 
*    by the general public by calling mintToken() and paying the mintCost price in ETH.
*
*
* https://abbey.ch/         -- Abbey Technology GmbH, Zug, Switzerland
* 
* ABBEY DEFI
* ========== 
* 1. Decentralized Finance (DeFi) is designed to be globally inclusive. 
* 2. Centralized finance is based around private share sales to wealthy individuals or
*    the trading of shares on national stock markets, both have high barriers to entry. 
* 3. The Abbey DeFi methodology offers public and private companies exposure to DeFi.
*
* Abbey is a Uniswap-based DeFi service provider that allows companies to offer people a 
* novel way to speculate on the success of their business in a decentralized manner.
* 
* The premise is both elegant and simple, the company commits to a token buyback based on 
* its sales revenue and commits to stabilize a tokens price by adding to the liquidity pool.
* 
* Using Abbey as a Uniswap DeFi management agency, the company spends sales revenue, as ETH, 
* buying one side of a bespoke Uniswap trading pair. The other side of the Uniswap pair 
* is the TNDY token.
* 
* DeFi traders wishing to speculate on the revenue growth of the company deposit ETH in return 
* for GCAC Uniswap tokens. The Uniswap Automated Market Maker ensures DeFi market 
* liquidity and legitimate price discovery. The more ETH that the company deposits over time, 
* the higher the value of the GCAC token, as held by DeFi speculators.
*
*/

pragma solidity 0.8.7;

import "./ERC20.sol";
import "./ERC721.sol";
import "./Ownable.sol";

/**
 * @title GCAC NFT Airdrop
 * @author Abbey Technology GmbH
 */
contract GCACNFT is ERC721, Ownable {

    /**
     * The next id that will be used by the mint function.
     */
    uint256 public nextId;

    /**
     * @notice The total number of NFTs created. 0-740 (741 in total) are the valid ids for this contract.
     */
    uint256 public maxId;

    /**
     * @notice The amount of Eth a caller must send to mint an NFT.
     */
    uint256 public mintCost;

    /**
     * @notice Allow the base of the tokenURI to be updated at a later date.
     */
    string public tokenBase;

    /**
     * @notice Cap the total number of tokens that can be minted.
     *         Set the mint cost to a prohibitively high value until we are ready to open minting to the public.
     *         Allocate the gold and rare tokens.
     *
     * @param name          The name of the token.
     * @param symbol        The short symbol for this token.     
     */
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        maxId = 740;
        mintCost = 100 ether;
        tokenBase = "https://abbey.ch/CryptoStrains/uri/";

        // Gold winner was token purchase closest to the cutoff (Aug 31st 2pm Irish)
        // https://etherscan.io/tx/0x2fc9dfe6153bb263df370dca25502b83b9c659948feb57c63864328ed0d624c0
        _mint(address(0x3E4Eaca25582F09311FCe4c88E926b83646ab8E1), 17);

        // Rare - top 20 holders of GCAC (excluding Treasury, Uniswap, Flip, PancakeSwap Router addresses).
        _mint(address(0x0Ae57135b8A151BC6eeBD958533Cc7a7feAa55B4), 1);
        _mint(address(0xF7E62E8Ba4D4ead31A372025B614815cfC944a1F), 39);
        _mint(address(0x97C3CecD4b2e415Ce3f69210f1D065323b668232), 76);
        _mint(address(0x285459F1dDf057eC04e7cCb7f72DDe81808eFf7b), 113);
        _mint(address(0x5B6b31f3F7Fa8f0F35CB05ef21ACbf9db317bf7E), 150);
        _mint(address(0x092999d9Ac9547F5121546049FACd5e64CcBe33a), 187);
        _mint(address(0x6841e5D118EEd03B8c6B01447d4206f02C0C24a9), 224);
        _mint(address(0xBd8dA360A84b0ddF0ac502DAc509075D4aAcb408), 261);
        _mint(address(0x64bd2Bbf23ad646d1807176C9F6f14Dc89eeb906), 298);
        _mint(address(0x59C404740b477b3cE337b1e4da69a932eB37A2f2), 335);
        _mint(address(0x0386579600befB0d276303D77703aC6c5DDc4D4c), 372);
        _mint(address(0x8379059Cc6163a7eAF98B34115330acB70aF6349), 409);
        _mint(address(0x8357Cc335EB7E12F7637E58A0ecA3ad691F085fB), 446);
        _mint(address(0x8fa9c29966AC5522DD5e7f128e87aE0b3A28F790), 483);
        _mint(address(0xa70669588f2cC50eb65C967d657cd55f88d1dd93), 520);
        _mint(address(0xd0E1eb27c713607EDd189880D6C6132D853626Ab), 557);
        _mint(address(0x5D75891416cf7104D59a869de1877F4E2b92d58c), 594);
        _mint(address(0x0a8eDbBD6D5F8a07f89BEFe6b724A85834151790), 631);
        _mint(address(0x36E25bD46678d5bbF06748e9de742c89BA1cd2E6), 668);
        _mint(address(0x2025A4c67D8A7ed870BCbBE25b022E211ca63741), 705);

        // This and the above address both had exactly 1,000 tokens.  As there are
        // no more rare ones to allocate, this address was given token id 0.
        _mint(address(0x064e75751bDA50670eFdB496B7160762BDA502aE), 0);
    }

    /**
     * @notice Owner controlled minting of tokens.  Bypasses the mint cost.
     *
     * @param who   The recipient of the token.
     */
    function mint(address who) public onlyOwner {
        mintInternal(who);
    }

    /**
     * @notice Allow a member of the public to mint their own token, paying mintCost to do so.
     */
    function mintToken() public payable {
        require(msg.value == mintCost, "You did not supply the correct amount of Ether to mint a token.");
        require(_msgSender() != owner(), "Owner should call mint.");

        mintInternal(_msgSender());
    }

    /**
     * @notice Common code called by mint() and mintToken() to actually allocate a token.
     *
     * @param who   The address to allocate the token to.
     */
    function mintInternal(address who) internal {
        while(nextId <=maxId && _exists(nextId))
            nextId++;

        require(nextId <= maxId, "Cannot mint more tokens, max reached.");

        _mint(who, nextId);
        nextId++;
    }

    /**
     * @notice Allow the owner to change the cost of the public minting a token.
     *
     * @param cost  The Eth price, in wei.
     */
    function setMintCost(uint256 cost) public onlyOwner {
        mintCost = cost;
    }

    /**
     * @notice Allow the owner to change the tokenURI.
     *
     * @param base  The new start of the tokenURI to the JSON files.
     */
    function setTokenBase(string memory base) public onlyOwner {
        tokenBase = base;
    }    

    /**
     * @notice Transfer the token creation fees to the owner.
     */
    function withdrawFees() public payable onlyOwner {
        (bool success, ) = owner().call{value:address(this).balance}('');
        require(success, "Transfer failed.");
    }

    /**
     * @notice The location of the token JSON files.
     */
    function _baseURI() internal view override returns (string memory) {
        return tokenBase;
    }
}