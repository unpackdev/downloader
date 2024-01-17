// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721URIStorage.sol";
import "./IERC2981.sol";
import "./IERC165.sol";
import "./Ownable.sol";

contract SidewalkCinema2022 is ERC721URIStorage, Ownable, IERC2981 {

    address payable private paymentsplitter;
    address amdin;

    constructor(
        address payable _paymentsplitter, 
        address admin
    ) ERC721("SidewalkCinema", "SWALK") {

        paymentsplitter = _paymentsplitter;
        
        for(uint i = 0 ; i < 9 ; i++) {
            _safeMint(admin, i);
        }

        _setTokenURI(0, "www.arweave.net/c0lQe4MZMxsBRL4AnpmOfXAW4TSJ8WhyQs_rgrspfXs");
        _setTokenURI(1, "www.arweave.net/yQ9xEoGjcDeblg_UpfxAtEN2vKbUpyvca33lg9GEVu0");
        _setTokenURI(2, "www.arweave.net/QUjPmrX_B18DvksX-xlU3FOA4TO7NCayTB3r9Fqhvbg");
        _setTokenURI(3, "www.arweave.net/cZq9oKGxcilhqTp1EkjNL3P69w_TSQqIvT5EqZgetsQ");
        _setTokenURI(4, "www.arweave.net/hDg57qV724J8mdc8oWuWpSTT8QUet-KaVUmCAL0c99Y");
        _setTokenURI(5, "www.arweave.net/Xl9p8Loa2P6KzNknYbnHz8gBQYkVZM4B-_w17-RJf3E");
        _setTokenURI(6, "www.arweave.net/fHAHCV57o1nQINE-N-0n6AXBPbjWlAyUzB6s5-htYZU");
        _setTokenURI(7, "www.arweave.net/n6BixYq3EPHgt4b6xVP21mEQnlHGb7Z7VD-RLnURPwo");
        _setTokenURI(8, "www.arweave.net/FPVBwfpd0L0IEC8_YKcDe6hTXHQjeau9zq9FDTNzmIo");
    }

    function changeTokenURI(uint256 tokenid, string calldata newURI) external onlyOwner {
        _setTokenURI(tokenid, newURI);
    }

    // EIP2981 standard royalties return.
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (paymentsplitter, (_salePrice * 1000) / 10000);
    }

    // Maintain flexibility to modify royalties recipient (could also add basis points).
    function _setRoyalties(address payable newRecipient) internal {
        require(newRecipient != address(0), "Royalties: new recipient is the zero address");
        paymentsplitter = newRecipient;
    }

    function setRoyalties(address payable newRecipient) external onlyOwner {
        _setRoyalties(newRecipient);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return (
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId)
        );
    }
}
