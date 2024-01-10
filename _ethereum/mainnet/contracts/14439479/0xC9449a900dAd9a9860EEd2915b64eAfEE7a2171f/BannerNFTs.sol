// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "./AbstractBannerNFTs.sol";
import "./BannerHelpers.sol";
import "./IERC20.sol";

contract BannerNFTs is AbsBannerNFTs {
    address internal _writerAddr;

    constructor(address wrContractAddr) AbsBannerNFTs() {
        _writerAddr = wrContractAddr;
    }

    function setContractAddresses(address newWriterAddr) external onlyOwner {
        _writerAddr = newWriterAddr;
    }

    function payAndMint(
        string memory name,
        string memory description,
        string memory txt,
        bool randomizeColors,
        address deliveryAddress
    ) external payable override nonReentrant returns (uint256) {
        // solhint-disable-next-line
        (bool success, bytes memory result) = _writerAddr.delegatecall(
            abi.encodeWithSignature(
                "payAndMint(string,string,string,bool,address)",
                name,
                description,
                txt,
                randomizeColors,
                deliveryAddress
            )
        );

        if (success) {
            return abi.decode(result, (uint256));
        } else {
            // solhint-disable-next-line
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function updateSvgAttributes(
        uint256 tokenId,
        string memory txt,
        string memory txtColor,
        string memory txtSize,
        string memory bgColor
    ) external payable override nonReentrant {
        // solhint-disable-next-line
        (bool success, ) = _writerAddr.delegatecall(
            abi.encodeWithSignature(
                "updateSvgAttributes(uint256,string,string,string,string)",
                tokenId,
                txt,
                txtColor,
                txtSize,
                bgColor
            )
        );

        if (!success) {
            // solhint-disable-next-line
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function getToken(uint256 tokenId)
        external
        view
        returns (BannerToken memory)
    {
        require(_exists(tokenId), "TOKEN_404");
        return _tokens[tokenId];
    }

    function getModifiableAttrs(uint256 tokenId)
        public
        pure
        override
        returns (BannerModifiableAttributes memory)
    {
        BannerModifiableAttributes memory ma;

        if (tokenId >= 8888) {
            // can also change bg color
            ma.canModifyBgColor = true;
        }
        if (tokenId >= 5000) {
            // can also change text size
            ma.canModifyTextSize = true;
        }
        if (tokenId >= 888) {
            // can only modify text color
            ma.canModifyTextColor = true;
        }

        // if we ever reach this...
        if (tokenId >= 10000) {
            // allow everything
            ma.canModifyEverything = true;
        }

        return ma;
    }

    function previewTokenURI(
        string memory name,
        string memory description,
        string memory bgColor,
        string memory text,
        string memory textColor,
        string memory textSize
    ) public pure returns (string memory) {
        return
            bh.previewTokenURI(
                name,
                description,
                bgColor,
                text,
                textColor,
                textSize
            );
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "TOKEN_404");
        return
            previewTokenURI(
                _tokens[tokenId].name,
                _tokens[tokenId].description,
                _tokens[tokenId].bgColor,
                _tokens[tokenId].text,
                _tokens[tokenId].textColor,
                _tokens[tokenId].textSize
            );
    }

    // solhint-disable-next-line
    receive() external payable {
        // Function to receive Ether. msg.data must be empty
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}(""); // solhint-disable-line
        require(success, "CANNOT_WITHDRAW");
    }

    function withdrawTokens(address tokenAddr) external onlyOwner {
        IERC20 token = IERC20(tokenAddr);
        uint256 tokenBalance = token.balanceOf(address(this));

        bool success = token.transfer(msg.sender, tokenBalance);
        require(success, "CANNOT_WITHDRAW");
    }

    // fallback function is called when msg.data is not empty
    fallback() external payable {}
}
