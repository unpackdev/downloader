// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./RoyaltiesV2Impl.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";

contract TRASHMOSH is ERC721URIStorage, Ownable, RoyaltiesV2Impl{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    address payable _addr;
    bool enabled;

    constructor() ERC721("TRASHMOSH", "TRSH") {
        _addr = payable (0x24A9bb6762688e327C5b63d8200770049f6d7c93);
        enabled = true;
    }

    function safeMint(address to, string memory _uri, uint256 ti) internal {
        _safeMint(to, ti);
        _setTokenURI(ti, _uri);
	setRoyalties(ti, _addr, 1000);
        _tokenIdCounter.increment();
    }

    function getTokenId() view public returns (uint256) {
        return _tokenIdCounter.current();
    }

    function disable() public onlyOwner {
        enabled = false;
    }

    function verifyThenMint(
        address to,
        string memory metadata,
        uint256 ti,
        uint256 deadline
    ) payable external {
        uint256 tokenId = _tokenIdCounter.current();
        require(ti == tokenId, "TOKEN ID MISMATCH");
        require(enabled, "MINTING DISABLED");
        require(block.timestamp < deadline, "SIGNED TRANSACTION EXPIRED");
        require(to != address(0), "ECDSA: INVALID SIGNATURE");
        require(msg.value >= 12e16, "PAYMENT FAILED (NOT ENOUGH ETHER)"); // (Th.)
        uint256 val = address(this).balance - 190000; // splitter gas cost
        (bool sent, ) = _addr.call{value: val, gas: 190000}("");
        require(sent, "PAYMENT FAILED (UNKNOWN)");

        safeMint(to, metadata, ti);
    }
    
	// RARIBLE ROYALTY FUNCTIONS
	function setRoyalties(uint _tokenId, address payable _royaltiesReceipientAddress, uint96 _percentageBasisPoints) public {
		LibPart.Part[] memory _royalties = new LibPart.Part[](1);
		_royalties[0].value = _percentageBasisPoints;
		_royalties[0].account = _royaltiesReceipientAddress;
		_saveRoyalties(_tokenId, _royalties);
	}
	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
		if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
			return true;
		}
		return super.supportsInterface(interfaceId);
	}
}
