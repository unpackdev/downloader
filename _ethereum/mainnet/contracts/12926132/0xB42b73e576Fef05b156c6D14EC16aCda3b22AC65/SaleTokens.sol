// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControlEnumerable.sol";
import "./IERC721.sol";
import "./SafeCast.sol";
import "./Context.sol";

interface ERC721Collection is IERC721 {
    function mint(address to) external;
    function totalSupply() view external returns (uint256);
    function maxSupply() view external returns (uint256);
}

contract SaleTokens is Context, AccessControlEnumerable {
    address[] public beneficiaryList;
    mapping(uint256 => uint256) public percentByBeneficiaryId;

    mapping(uint256 => uint256) private claimedAmountByBeneficiaryId;

    uint256 public price;
    uint256 public salesAmount;
    ERC721Collection public nftCollection;

    uint256 constant PERCENT_PRECISION = 10000;
    address payable public fundAddress;

    event SoldNFT(
        address indexed _caller,
        uint256 indexed _count
    );

    /**
     * @dev Constructor of the contract.
     * @param _nftCollection - Address of the collection
     * @param _beneficiaryList - List beneficiary
     * @param _beneficiaryPercentList - percent multiple toPERCENT_PRECISION
     * @param _price - price in WEI (1e18 = 1eth)
     */
    constructor(
        ERC721Collection _nftCollection,
        address[] memory _beneficiaryList,
        uint256[] memory _beneficiaryPercentList,
        uint256 _price,
        address payable _fundAddress
    ) {
        nftCollection = _nftCollection;
        price = _price;
        fundAddress = _fundAddress;
        _setBeneficiaries(_beneficiaryList, _beneficiaryPercentList);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
* @dev Buy NFT for ETH
* @param _count - count
*/
    function buyNFT(uint256 _count) public payable {
        require(_count >= 1, "Count must more or equal 1");
        require(_count <= 25, "Count must more or equal 25");

        uint256 balance = msg.value;
        require(balance == price*_count, "Not enough sent");
        require(nftCollection.totalSupply()+_count <= nftCollection.maxSupply(), "Not enough nft for buy");
        salesAmount += balance;

        for (uint256 i = 0; i < _count; i++) {
            nftCollection.mint(_msgSender());
        }
        emit SoldNFT(_msgSender(), _count);
    }

    function availableRewardForClaim(address beneficiary)
    public view returns (uint256)
    {
        for (uint256 beneficiaryId = 0; beneficiaryId < beneficiaryList.length; beneficiaryId++) {
            if (beneficiaryList[beneficiaryId] == beneficiary) {
                uint256 contractBalance = address(this).balance;
                uint256 shareSize = contractBalance / PERCENT_PRECISION;
                require(beneficiary != address(0), "INCORRECT ADDRESS");
                uint256 share = percentByBeneficiaryId[beneficiaryId];
                require(share <= PERCENT_PRECISION, "INCORRECT PERCENT");
                return shareSize * share;
            }
        }
        require(false, "INCORRECT ADDRESS");
        return 0;
    }

    function claimAllReward() external {
        uint256 contractBalance = address(this).balance;
        uint256 shareSize = contractBalance / PERCENT_PRECISION;
        for (uint256 beneficiaryId = 0; beneficiaryId < beneficiaryList.length; beneficiaryId++) {
            address beneficiary = beneficiaryList[beneficiaryId];
            require(beneficiary != address(0), "INCORRECT ADDRESS");
            uint256 share = percentByBeneficiaryId[beneficiaryId];
            require(share <= PERCENT_PRECISION, "INCORRECT PERCENT");
            uint256 available = shareSize * share;
            if (available > 0) {
                payable(beneficiary).transfer(available);
            }
        }
    }

    function _setBeneficiaries(
        address[] memory _beneficiaryList,
        uint256[] memory _beneficiaryPercentList
    ) private {
        require(_beneficiaryList.length == _beneficiaryPercentList.length, "Lists must be same length");

        delete beneficiaryList;
        uint256 sumPercent = 0;

        for (uint256 i = 0; i < _beneficiaryList.length; i++) {
            beneficiaryList.push(_beneficiaryList[i]);
            percentByBeneficiaryId[i] = _beneficiaryPercentList[i];
            sumPercent += _beneficiaryPercentList[i];
        }
        require(sumPercent == PERCENT_PRECISION, "Sum percent must 100%");
    }

    function setPrice(uint256 _price) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "FluxArtNFT: must have admin role");
        price = _price;
    }

    function setBeneficiaries(
        address[] memory _beneficiaryList,
        uint256[] memory _beneficiaryPercentList
    ) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "FluxArtNFT: must have admin role");
        _setBeneficiaries(_beneficiaryList, _beneficiaryPercentList);
    }

    function mint(address _to, uint256 _count) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "FluxArtNFT: must have admin role");
        for (uint256 i = 0; i < _count; i++) {
            nftCollection.mint(_to);
        }
    }

    function finalize() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "FluxArtNFT: must have admin role");
        selfdestruct(fundAddress);
    }
}
