// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

interface NumberBoard {
	function acceptBuyNowOffer(uint256 theNum) external payable;
	function placeBuyNowOffer(uint256 theNum, uint256 price) external;
	function withdrawEarnings() external;
	function updateMessage(uint256 theNum, string calldata aMessage) external;
}

/// @author William Entriken
contract WrappedNumberBoard is ERC721Enumerable, Ownable {
    NumberBoard constant public NUMBERBOARD = NumberBoard(0x9249133819102b2ed31680468c8c67F6Fe9E7505);
    uint256 constant MIN_PRICE = 1e15; // 1 finney
    string _baseURIStorage;
    
    constructor() ERC721("Wrapped Number Board", "WNB") {}

    function wrap(uint256 theNum) payable external {
        NUMBERBOARD.acceptBuyNowOffer{value: msg.value}(theNum);
        _safeMint(msg.sender, theNum);
    }
    
    // To unwrap you must do these in immediate succession:
    //  1. Call unwrap
    //  2. Execute acceptBuyNowOffer on underlying contract to take Number Board card
    //  3. Collect remaining funds here with withdrawEarnings (optional)
    //  4. Revent if anything didn't work
    // Because processing multiple orders in immediate succession is not possible with externally-owned accounts (e.g.
    // MetaMask), and because all other unwraps are at risk of sniping, unwrapping is restricted to smart contracts.
    function unwrap(uint256 theNum) external {
        require(ownerOf(theNum) == msg.sender);
        require(tx.origin != msg.sender, "Only a smart contract can unwrap, due to sniping risk");
        NUMBERBOARD.placeBuyNowOffer(theNum, MIN_PRICE);
        _burn(theNum);
    }
    
    // Yes, intentionally open access, see notes in unwrap
    function withdrawEarnings() external {
        NUMBERBOARD.withdrawEarnings();
        payable(msg.sender).transfer(address(this).balance);
    }
    
	function updateMessage(uint256 theNum, string calldata aMessage) external {
        require(ownerOf(theNum) == msg.sender);
        NUMBERBOARD.updateMessage(theNum, aMessage);
	}

    function setBaseURI(string calldata newBaseURI) onlyOwner external {
        _baseURIStorage = newBaseURI;
    }

    function _baseURI() override internal view returns (string memory) {
        return _baseURIStorage;
    }
}