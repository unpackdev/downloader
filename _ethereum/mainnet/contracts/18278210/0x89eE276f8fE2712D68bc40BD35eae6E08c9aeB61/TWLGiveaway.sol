// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

// Importing dependencies
import "./Strings.sol";
import "./Ownable2Step.sol";
import "./ERC721A.sol";

/**
 * @title TWLGiveaway
 * @notice This contract handles the giveaway to NFT holders.
 */
contract TWLGiveaway is Ownable2Step {
    uint256 public drawBlock;
    address public nftContract;
    address public host;
    address public winner;
    uint256 public winnerTokenId;

    event WinnerSelected(address winner, uint256 tokenId);

    ERC721A private _nftInstance;

    constructor() Ownable(msg.sender) {
        host = msg.sender;
    }

    function setNFTContract(address _nftContract) public onlyOwner {
        require(_nftContract != address(0), "NFT contract address cannot be zero address");
        nftContract = _nftContract;
        _nftInstance = ERC721A(_nftContract);
    }

    function setHost(address _host) public onlyOwner {
        require(_host != address(0), "Host address cannot be zero address");
        host = _host;
    }

    modifier onlyHost() {
        require(msg.sender == host, "Only the host can call this function");
        _;
    }

    function openGiveaway() public onlyHost {
        require(!(drawBlock >= block.number && block.number <= drawBlock + 256), "Invalid state to open giveaway");
        drawBlock = block.number + 15;
    }

    function isOpen() public view returns (bool) {
        return block.number >= drawBlock && block.number <= drawBlock + 256;
    }

    function getWinnerTokenIdForBlock() public view returns (uint256) {
        require(block.number >= drawBlock, "Giveaway not yet drawn");
        require(block.number <= drawBlock + 256, "Giveaway expired");

        uint256 blockHashAsInt = uint256(blockhash(drawBlock));
        return blockHashAsInt % _nftInstance.totalSupply() + 1;
    }

    function mrBeastMode() public onlyHost {
        winnerTokenId = getWinnerTokenIdForBlock();
        winner = _nftInstance.ownerOf(winnerTokenId);

        uint256 prizeAmount = address(this).balance;
        require(prizeAmount > 0, "No prize to distribute");
        emit WinnerSelected(winner, winnerTokenId);

        _sendEther(payable(winner), prizeAmount);
    }

    receive() external payable { }

    function _sendEther(address payable recipient_, uint256 amount) internal {
        // Ensure sufficient balance.
        require(address(this).balance >= amount, "insufficient balance");
        // Send the value.
        (bool success, ) = recipient_.call{value: amount, gas: gasleft()}("");
        require(success, "recipient reverted");
    }

    function withdraw() public onlyOwner {
        _sendEther(payable(msg.sender), address(this).balance);
    }
}
