// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721Pausable.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

abstract contract Tradable {
    using SafeMath for uint256;

    struct Recipient {
        address recipient;
        uint256 points;
    }

    address internal _proxyAddress;
    Recipient[] private _saleRecipients;
    uint256 private _sellerFeeBasisPoints;
    Recipient[] private _feeRecipients;
    string private _contractURI;

    mapping(uint256 => address) internal _creators;
    mapping(uint256 => string) internal _tokenURIs;

    constructor(
        address proxy,
        Recipient[] memory saleRecipients,
        uint256 sellerFeeBasisPoints,
        Recipient[] memory feeRecipients,
        string memory url
    ) {
        require(
            sellerFeeBasisPoints <= 99,
            "Fee must be less than or equal to 99"
        );
        _proxyAddress = proxy;
        uint256 allSalePoints = 0;
        for (uint256 i = 0; i < saleRecipients.length; i++) {
            _saleRecipients.push(saleRecipients[i]);
            allSalePoints += saleRecipients[i].points;
        }
        require(allSalePoints == 100, "The sum of sale shares must be 100");
        _sellerFeeBasisPoints = sellerFeeBasisPoints;
        uint256 allFeePoints = 0;
        for (uint256 i = 0; i < feeRecipients.length; i++) {
            _feeRecipients.push(feeRecipients[i]);
            allFeePoints += feeRecipients[i].points;
        }
        require(allFeePoints == 100, "The sum of fee shares must be 100");
        _contractURI = url;
    }

    function getProxyAddress() public view returns (address) {
        return _proxyAddress;
    }

    function getSaleRecipients() public view returns (Recipient[] memory) {
        return _saleRecipients;
    }

    function getFeeRecipients() public view returns (Recipient[] memory) {
        return _feeRecipients;
    }

    function getSellerFeeBasisPoints() public view returns (uint256) {
        return _sellerFeeBasisPoints;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * 获取第一次销售分成的数量
     */
    function getFistAmount(address owner, uint256 tokenId)
        public
        view
        virtual
        returns (uint256);

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
}
