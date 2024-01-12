//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC2981.sol";
import "./IERC20.sol";

import "./Ownable.sol";

import "./Base64.sol";
import "./Strings.sol";

interface CSInterface {
    function redeemAsMintPass(uint256 _tokenId) external returns (bool);
}

contract CSCollectionOne is ERC721, IERC2981, Ownable {
    using Strings for uint256;

    uint256 public counter;

    CSInterface public collectiveStrangersContract =
        CSInterface(0xA95cCcbCA85D4bB99549ec09E3D83cE1E88988aE);

    // Collection metatdata URI
    string baseTokenURI;

    constructor(string memory _baseURI)
        ERC721("CS Community Collection", "CSCC")
        Ownable()
    {
        baseTokenURI = _baseURI;
    }

    /**
     * @dev Required to receive royalty payments to the smart contract
     */
    receive() external payable {}

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============

    function mintToken(address _to, uint256 tokenId) public onlyOwner {
        require(
            collectiveStrangersContract.redeemAsMintPass(tokenId),
            "This token already redeemed"
        );
        unchecked {
            ++counter;
        }
        _mint(_to, counter);
    }

    function airdropTokens(
        address[] calldata _recipients,
        uint256[] calldata _tokenId
    ) external onlyOwner {
        for (uint256 i = 0; i < _recipients.length; ) {
            mintToken(_recipients[i], _tokenId[i]);
            unchecked {
                ++i;
            }
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    // ============ PUBLIC READ-ONLY FUNCTIONS ============
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            bytes(baseTokenURI).length > 0
                ? string(
                    abi.encodePacked(baseTokenURI, tokenId.toString(), ".json")
                )
                : "";
    }

    // ============ FUNCTION OVERRIDES ============

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC165-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");

        return (address(this), (salePrice * 5) / 100);
    }
}
