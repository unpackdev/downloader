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
        uint256 _price
    ) {
        nftCollection = _nftCollection;
        price = _price;
        _setBeneficiaries(_beneficiaryList, _beneficiaryPercentList);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
* @dev Buy NFT for ETH
* @param _count - count
*/
    function buyNFT(uint256 _count) public payable {
        require(_count >= 1, "Count must more or equal 1");

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
        uint256 available = 0;
        for (uint256 beneficiaryId = 0; beneficiaryId < beneficiaryList.length; beneficiaryId++) {
            if (beneficiaryList[beneficiaryId] == beneficiary) {
                uint256 percent = percentByBeneficiaryId[beneficiaryId];
                available += salesAmount * percent / PERCENT_PRECISION;
                uint256 claimedAmount = claimedAmountByBeneficiaryId[beneficiaryId];
                if (available > claimedAmount) {
                    available -= claimedAmount;
                    return available;
                } else {
                    return 0;
                }
            }
        }
        return 0;
    }

    function claimAllReward() external {
        for (uint256 beneficiaryId = 0; beneficiaryId < beneficiaryList.length; beneficiaryId++) {
            address beneficiary = beneficiaryList[beneficiaryId];
            require(beneficiary != address(0), "INCORRECT ADDRESS");
            uint256 percent = percentByBeneficiaryId[beneficiaryId];
            require(percent <= PERCENT_PRECISION, "INCORRECT PERCENT");
            uint256 available = salesAmount * percent / PERCENT_PRECISION;
            uint256 claimedAmount = claimedAmountByBeneficiaryId[beneficiaryId];
            available -= claimedAmount;
            if (available > 0) {
                claimedAmountByBeneficiaryId[beneficiaryId] += available;
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
}
