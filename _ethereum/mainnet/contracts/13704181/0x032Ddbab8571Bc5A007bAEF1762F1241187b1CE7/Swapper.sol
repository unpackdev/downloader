// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.7;


import "./Ownable.sol";
import "./IERC20.sol";
import "./Provenance.sol";

interface IBaseToken {
    function burn(uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external returns (address);
    function mint(address to) external;
}

contract Swapper is Ownable, Provenance {

    address public tokenToBurn;
    address public tokenToMint;
    uint256 public batchSize;
    uint256 public keyDeadline;

    /* ------------------------------- Constructor ------------------------------ */

    constructor(
        address _tokenToBurn,
        address _tokenToMint,
        uint256 _batchSize,
        uint256 _keyDeadline,
        bytes32 _provenanceHash
    ) {
        require(_tokenToBurn != address(0), "Swapper: tokenToBurn cannot be zer0 address");
        require(_tokenToMint != address(0), "Swapper: tokenToMint cannot be zer0 address");
        require(_keyDeadline > block.timestamp, "Swapper: keyDeadline must be later than now");
        require(_batchSize != 0, "Swapper: batchSize cannot be 0");

        tokenToBurn = _tokenToBurn;
        tokenToMint = _tokenToMint;
        batchSize = _batchSize;
        keyDeadline = _keyDeadline;

        _setProvenance(_provenanceHash);

    }


    /* ------------------------------ Owner Methods ----------------------------- */

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function sweep(address token, address to, uint256 amount)
        external
        onlyOwner
        returns (bool)
    {    
        return IERC20(token).transfer(to, amount);
    }


    /* ----------------------------- Public Methods ----------------------------- */

    function swap(uint256 tokenId)
        public
    {
        require(IBaseToken(tokenToBurn).ownerOf(tokenId) == msg.sender, "Swapper: only current owner may swap");
        require(keyDeadline >= block.timestamp, "Swapper: redemption deadline passed");
        
        IBaseToken(tokenToBurn).burn(tokenId);
        IBaseToken(tokenToMint).mint(msg.sender);

        // First swap sets offset.
        _setStartingBlock(1, 1);

    }

    function finalizeReveal() public {
        require(batchSize != 0, "Swapper: set batch size first");
        _finalizeStartingIndex(batchSize);
    }
}