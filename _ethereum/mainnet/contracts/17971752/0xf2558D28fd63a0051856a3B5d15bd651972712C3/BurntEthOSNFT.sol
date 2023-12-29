pragma solidity ^0.8.17;

import "./ERC721URIStorage.sol";
import "./ETHOSNFT.sol";

contract BurntEthOSNFT is ERC721URIStorage {
    address public owner;

    EthOSNFT public ethOSNFT;

    constructor(EthOSNFT _ethOSNFT) ERC721("Burnt ethOS Phone", "BETHOSPHONE") {
        owner = msg.sender;
        ethOSNFT = _ethOSNFT;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function toUInt256(bool x) internal pure returns (uint256 r) {
        assembly {
            r := x
        }
    }

    function mintBPhone(
        uint256 tokenId,
        address receiver
    ) public onlyOwner {
        _mint(receiver, tokenId);

        _setTokenURI(
            tokenId,
            ""
        );
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            string.concat(
                ethOSNFT.tokenURI(tokenId),
                "&b=1"
            );
    }
}