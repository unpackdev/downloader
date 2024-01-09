pragma solidity ^0.6.6;

import "./Ownable.sol";
import "./ERC721.sol";

/**
 * @dev RicochetNFTBase contract.
 * @notice Setup admin control functional, include MINT_FEE_PER_TOKEN, and Total Supply
 */
contract RicochetNFTBase is Ownable, ERC721 {
    uint256 public constant LIMIT_TOKEN_PER_TX = 1;

    uint256 public MAX_RICOCHET;
    uint256 public MINT_FEE_PER_TOKEN;

    // status = false <=> contract offline
    // status = true <=> contract online
    // token only can mint when contract online
    // admin only can setup contract when contract offline
    bool public status;

    /**
     * @param _mintFeePerToken The Fee (in ETH) collector/user pays for Ricochet when one token is minted.
     * @param _MAX_RICOCHET Total supply of contract
     */
    constructor(uint256 _mintFeePerToken, uint256 _MAX_RICOCHET)
        public
        ERC721("Ricochet", "RICOCHET")
    {
        MAX_RICOCHET = _MAX_RICOCHET;
        MINT_FEE_PER_TOKEN = _mintFeePerToken;
    }

    /**
     * @dev ensure contract is online
     */
    modifier online() {
        require(status, "Contract must be online.");
        _;
    }

    /**
     * @dev ensure contract is offline
     */
    modifier offline() {
        require(!status, "Contract must be offline.");
        _;
    }

    /**
     * @dev ensure collector pays for mint token
     */
    modifier mintable(uint256 numberToken, uint256 totalSupply) {
        require(numberToken <= LIMIT_TOKEN_PER_TX, "Number Token invalid");
        require(msg.value >= numberToken.mul(MINT_FEE_PER_TOKEN), "Payment error");
        require(totalSupply.add(numberToken) < MAX_RICOCHET, "Sold out");
        _;
    }

    /**
     * @dev change status from online to offline and vice versa
     */
    function toggleActive() public onlyOwner returns (bool) {
        status = !status;
        return true;
    }

    // TODO: should set fix MINT_FEE_PER_TOKEN
    function setMintFee(uint256 _mintFeePerToken)
        public
        onlyOwner
        offline
        returns (bool)
    {
        MINT_FEE_PER_TOKEN = _mintFeePerToken;
        return true;
    }


    /**
     * @dev withdraw ether to owner/admin wallet
     * @notice ONLY owner can call this function
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        msg.sender.transfer(balance);
    }
}