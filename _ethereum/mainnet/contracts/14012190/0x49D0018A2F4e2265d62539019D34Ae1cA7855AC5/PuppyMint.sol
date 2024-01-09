// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ERC1155.sol";
import "./Ownable.sol";

/**
 * puppymint semi-fungible token very wow.
 *
 * allows users to wrap their PUP erc20 tokens into erc1155 semi-fungible-tokens (sfts) of specific denominations.
 *
 * anybody can mint a coin by storing PUP erc20 in this contract.
 * anybody can redeem a coin for its ascribed PUP erc20 value at any time.
 * anybody can swap one coin for another coin if they have the same PUP value.
 * some coin types can be "limited edition" and have a capped supply, while others are only implicitly capped by the max total supply of the erc20 PUP.
 */
contract PuppyMint is ERC1155, Ownable {
    string public name = "PuppyCoin";
    string public symbol = "PUP";
    string private _metadataURI = "https://assets.puppycoin.fun/metadata/{id}.json";
    string private _contractUri = "https://assets.puppycoin.fun/metadata/contract.json";

    IPuppyCoin puppyCoinContract = IPuppyCoin(_pupErc20Address());
    uint private MILLI_PUP_PER_PUP = 1000; // PUP erc20 has 3 decimals.
    uint private PUP_MAX_SUPPLY = 21696969696;

    struct TokenInfo {
        uint id;
        uint valueInPUP;
        uint numInCirculation;
        uint maxSupply;
    }
    mapping(uint => TokenInfo) public tokenInfoById;

    // the next token type created will have this id. this gets incremented with each new token type.
    uint public nextAvailableTokenId = 1;

    // owner can freeze the base uri.
    bool public baseUriFrozen = false;

    constructor() public ERC1155(_metadataURI) {}

    /**
     * gets the contract address for the PUP erc20 token.
     */
    function _pupErc20Address() internal view returns(address) {
        address addr;
        assembly {
            switch chainid()
            case 1 {
                // mainnet
                addr := 0x2696Fc1896F2D5F3DEAA2D91338B1D2E5f4E1D44
            }
            case 4 {
                // rinkeby
                addr := 0x183B665119F1289dFD446a2ebA29f858eE0D3224
            }
        }
        return addr;
    }

    /**
     * mint one or more puppymint sfts of the provided id.
     *
     * sender must have first called approve() on the PUP token contract w/ this contract's address
     * for greater than or equal to the token id's pup value times numToMint.
     */
    function mint(uint tokenId, uint numToMint) public {
        _requireLegalTokenId(tokenId);

        // transfer PUP from the sender to this contract.
        uint256 totalCostMilliPup = tokenInfoById[tokenId].valueInPUP * MILLI_PUP_PER_PUP * numToMint;
        puppyCoinContract.transferFrom(
            msg.sender,
            address(this),
            totalCostMilliPup
        );

        _mintToSender(tokenId, numToMint);
    }

    /**
     * mint one (or more) sfts with the given tokenId to the sender.
     * ensures the mint will not exceed the token's max supply.
     */
    function _mintToSender(uint tokenId, uint numToMint) internal {
        tokenInfoById[tokenId].numInCirculation += numToMint;
        require(tokenInfoById[tokenId].numInCirculation <= tokenInfoById[tokenId].maxSupply, "minting would exceed max supply");
        _mint(msg.sender, tokenId, numToMint, "");
    }

    /**
     * redeem one (or more) sfts for PUP.
     */
    function redeem(uint tokenId, uint numToRedeem) public {
        _requireLegalTokenId(tokenId);

        // burn the sft(s).
        _burnFromSender(tokenId, numToRedeem);

        // send PUP to the caller.
        uint milliPupToSend = tokenInfoById[tokenId].valueInPUP * MILLI_PUP_PER_PUP * numToRedeem;
        puppyCoinContract.transfer(
            msg.sender,
            milliPupToSend
        );
    }

    /**
     * burn one or more tokens from the sender and decrement the token's numInCirculation.
     */
    function _burnFromSender(uint tokenId, uint numToBurn) internal {
        tokenInfoById[tokenId].numInCirculation -= numToBurn;
        _burn(msg.sender, tokenId, numToBurn);
    }

    /**
     * swap one token for another one. the two tokens must have the same PUP value.
     */
    function swap(uint burnTokenId, uint mintTokenId, uint numToSwap) public {
        _requireLegalTokenId(burnTokenId);
        _requireLegalTokenId(mintTokenId);
        require(tokenInfoById[burnTokenId].valueInPUP == tokenInfoById[mintTokenId].valueInPUP, "tokens are not the same value");

        _burnFromSender(burnTokenId, numToSwap);
        _mintToSender(mintTokenId, numToSwap);
    }

    function _requireLegalTokenId(uint id) internal view {
        // the contract owner must have initialized this tokenId.
        // if the token was never set, then its id will be 0.
        require(tokenInfoById[id].id != 0, "illegal token id");
    }

    function contractURI() public view returns (string memory) {
      return _contractUri;
    }

    /**
     * creates a new token type with the provided value in PUP. 
     */
    function createNewToken(uint tokenValuePup)
        public
        onlyOwner
    {
        // a unlimited token is just one where PUP_MAX_SUPPLY is the limit.
        createNewLimitedEditionToken(tokenValuePup, PUP_MAX_SUPPLY);
    }

    function createNewLimitedEditionToken(uint tokenValuePup, uint maxSupply) public onlyOwner {
        tokenInfoById[nextAvailableTokenId] = TokenInfo(nextAvailableTokenId, tokenValuePup, 0, maxSupply);
        nextAvailableTokenId++;
    }

    function setContractUri(string calldata newUri) public onlyOwner {
      _contractUri = newUri;
    }

    function setBaseUri(string calldata newUri) public onlyOwner {
        require(!baseUriFrozen, "base uri is frozen");
        _setURI(newUri);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return OpenSeaGasFreeListing.isApprovedForAll(owner, operator) || super.isApprovedForAll(owner, operator);
    }

    /**
     * DANGER BETCH! only call this if you're sure the current URI is good forever.
     */
    function freezeBaseUri() public onlyOwner {
        baseUriFrozen = true;
    }
}

/**
 * very wow interface for the PUP erc-20 token.
 */
interface IPuppyCoin {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function transfer(
        address recipient,
        uint256 amount
    ) external;
}

/**
 * much trust allow gas-free listing on opensea.
 */
library OpenSeaGasFreeListing {
    function isApprovedForAll(address owner, address operator) internal view returns (bool) {
        ProxyRegistry registry;
        assembly {
            switch chainid()
            case 1 {
                // mainnet
                registry := 0xa5409ec958c83c3f309868babaca7c86dcb077c1
            }
            case 4 {
                // rinkeby
                registry := 0xf57b2c51ded3a29e6891aba85459d600256cf317
            }
        }

        return address(registry) != address(0) && address(registry.proxies(owner)) == operator;
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}