pragma solidity ^0.8.4;
// SPDX-Licence-Identifier: RIGHT-CLICK-SAVE-ONLY


import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC1820Registry.sol";
import "./ReentrancyGuard.sol";
import "./IERC777Recipient.sol";
import "./IERC777.sol";

import "./community_interface.sol"; 
import "./recovery.sol";
import "./configuration.sol";
import "./token_interface.sol";
import "./console.sol";

contract tokyo_square is ERC721Enumerable, configuration , Ownable, recovery , ReentrancyGuard, token_interface {
    using Strings  for uint256;

    mapping (address => bool)       public override permitted;

    string                                          _tokenRevealedBaseURI_1;
    string                                          _tokenRevealedBaseURI_2;
    uint256                                         _ts1;                   // total supply when baseURI set
    bool                                            _secondReceived;

    uint256                                         nextToken;

    event Allowed(address,bool);
    event Locked(bool);

    modifier onlyAllowed() {
        require(permitted[msg.sender] || (msg.sender == owner()),"Unauthorised");
        _;
    }

    constructor( ) ERC721(_name,_symbol) {
    }

    function setAllowed(address _addr, bool _state) external override onlyAllowed {
        permitted[_addr] = _state;
        emit Allowed(_addr,_state);
    }

    function mintCards(uint256 numberOfCards, address recipient) external override onlyAllowed {
        _mintCards(numberOfCards,recipient);
    }

    function _mintCards(uint256 numberOfCards, address recipient) internal {
        uint256 next = nextToken;
        require((nextToken += numberOfCards) < _maxSupply,"This would exceed the number of cards available");
        for (uint j = 0; j < numberOfCards; j++) {
            _mint(recipient,next + j);
        }
    }

    // RANDOMISATION --cut-here-8x------------------------------

    function setRevealedBaseURI_1(string calldata revealedBaseURI) external onlyOwner {
        _tokenRevealedBaseURI_1 = revealedBaseURI;
        _ts1 = totalSupply();
    }
    function setRevealedBaseURI_2(string calldata revealedBaseURI) external onlyOwner {
        _secondReceived = true;
        _tokenRevealedBaseURI_2 = revealedBaseURI;
    }

    function setPreRevealURI(string memory _pre) external onlyOwner {
        _tokenPreRevealURI = _pre;
    }
 
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), 'Token does not exist');
        string memory file = tokenId.toString();
        string memory revealedBaseURI = _tokenRevealedBaseURI_1;

        if ((tokenId >= _ts1) && !_secondReceived) return string(abi.encodePacked(_tokenPreRevealURI,file,".json"));
        if (tokenId >= _ts1) {
            revealedBaseURI = _tokenRevealedBaseURI_2;
        }

        return string(abi.encodePacked(revealedBaseURI,file,".json"));
        //
    }

    function tellEverything() external view override returns (TKS memory) {
        return TKS(
            totalSupply(),
            _ts1,
            _tokenPreRevealURI,
            _lockTillSaleEnd,
            _secondReceived
        );
    }



}
