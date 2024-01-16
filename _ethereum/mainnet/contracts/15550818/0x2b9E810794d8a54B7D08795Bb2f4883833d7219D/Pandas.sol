// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./Strings.sol";
import "./ERC721Royalty.sol";

contract Pandas is ERC721Royalty{ 
	using Strings for uint256;

    //------------------//
    //     VARIABLES    //
    //------------------//

	uint256 public maxSupply = 1111;
    uint256 public totalMinted = 1;

	bool public sale = false;
    bool public frozen = false;

	string public baseURI;

	address private _owner;

    mapping(address => bool) public minted;

	error Paused();
	error MaxSupply();
	error AccessDenied();
    error MintLimit();

	constructor(string memory initialURI)
	ERC721("PrOoF oF pAnDAs", "PoP"){
		_owner = msg.sender;
        _safeMint(msg.sender, 1);
        baseURI = initialURI;
		_setDefaultRoyalty(msg.sender, 999);
	}

    //------------------//
    //     MODIFIERS    //
    //------------------//

	modifier onlyOwner {
		if(msg.sender != _owner) { revert AccessDenied(); }
		_;
	}
    
    //------------------//
    //       MINT       //
    //------------------//

	function mint() external {
		if(sale == false) revert Paused();
		if(1 + totalMinted > maxSupply) revert MaxSupply();
        if(minted[msg.sender] == true) revert MintLimit();

        unchecked{
            minted[msg.sender] = true;
            totalMinted += 1;
        }
        _safeMint(msg.sender, totalMinted, "");
	}

    //------------------//
    //      SETTERS     //
    //------------------//

    function freezeMetadata() external onlyOwner {
        frozen = true;
    }

    // function setRoyaltyContract(address receiver) external onlyOwner {
    //     royaltyContract = receiver;
    // }

	function startSale() external onlyOwner {
		sale = true;
	}

	function updateMetadata(string memory _newBaseURI) external onlyOwner {
        if(frozen == true) { revert Paused(); }
		baseURI = _newBaseURI;
	}

    //------------------//
    //      GETTERS     //
    //------------------//

	function owner() external view returns(address) {
		return _owner;
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
		string memory currentBaseURI = _baseURI();
		return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
	}
 
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyOwner{
      _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    //------------------//
    //       MISC       //
    //------------------//

	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}

	function withdraw() external onlyOwner {
		payable(_owner).transfer(address(this).balance);
	}

	fallback() payable external {}
	receive() payable external {}
}