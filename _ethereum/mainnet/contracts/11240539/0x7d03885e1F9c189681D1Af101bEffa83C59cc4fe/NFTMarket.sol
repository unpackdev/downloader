pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./ERC721.sol";
import "./IERC721Receiver.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Address.sol";
import "./hotpotinterface.sol";
import "./ILoan.sol";
import "./BytesLib.sol";

/**
 * @title NFTMarket contract that allows atomic swaps of ERC20 and ERC721
 */
contract NFTMarket is IERC721Receiver, Ownable {
    using Address for address;
    using SafeMath for uint256;
    using BytesLib for bytes;
    using Strings for uint256;

    using EnumerableSet for EnumerableSet.UintSet;

    event Swapped(
        address indexed _buyer,
        address indexed _seller,
        uint256 indexed _tokenId,
        uint256 _price,
        uint8 grade
    );
    event Listed(
        address indexed _seller,
        uint256 indexed _tokenId,
        uint256 _price
    );
    event Unlisted(address indexed _seller, uint256 indexed _tokenId);

    mapping(uint256 => Reservation) public reservations;

    struct Reservation {
        uint256 tokenId;
        address owner;
        uint256 price;
    }

    IERC20 public erc20;
    ERC721 public erc721;
    IHotPot public hotpot;
    ILoan public loan;

    address public rewardAddress;
    address public devAddress;

    uint256 public taxRatio = 2;
    uint256 public taxDev = 1;

    uint256 public updatePosibility = 4;

    mapping(uint256 => uint256) public priceOf;
    mapping(uint256 => address) public sellerOf;

    EnumerableSet.UintSet internal listSet;

    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    constructor(
        address _reward,
        address _nft,
        address _hotpot,
        address _loan,
        address _dev
    ) public {
        require(_dev != address(0));
        require(_reward != address(0));
        require(_nft != address(0));
        require(_hotpot != address(0));
        require(_nft.isContract(), "It's not contract address!");
        require(_reward.isContract(), "It's not contract address!");
        require(_hotpot.isContract(), "It's not contract address!");
        require(_loan.isContract(), "It's not contract address!");
        rewardAddress = _reward;
        devAddress = _dev;
        erc20 = IERC20(_hotpot);
        hotpot = IHotPot(_nft);
        erc721 = ERC721(_nft);
        loan = ILoan(_loan);
    }

    function setRewardAddress(address _addr) external onlyOwner {
        require(_addr.isContract(), "It's not contract address!");
        rewardAddress = _addr;
    }

    function setDevAddress(address _addr) external onlyOwner {
        require(_addr != address(0));
        devAddress = _addr;
    }

    function setHotPotTicket(address _addr) external onlyOwner {
        require(_addr.isContract(), "It's not contract address!");
        hotpot = IHotPot(_addr);
        erc721 = ERC721(_addr);
    }

    function setERC20(address _addr) external onlyOwner {
        require(_addr.isContract(), "It's not contract address!");
        erc20 = IERC20(_addr);
    }

    function setLoan(address _addr) external onlyOwner {
        require(_addr.isContract(), "It's not contract address!");
        loan = ILoan(_addr);
    }

    function setTax(uint256 _ratio) external onlyOwner {
        require(_ratio < 100, "Tax can not be greater than 100!");
        taxRatio = _ratio;
    }

    function setUpdatePosibility(uint256 _posibility) external onlyOwner {
        require(_posibility > 0 && _posibility < 100);
        updatePosibility = _posibility;
    }

    function getListSize() external view returns (uint256) {
        return listSet.length();
    }

    function getListToken() external view returns (uint256[] memory) {
        uint256 loanSize = listSet.length();
        uint256[] memory data = new uint256[](loanSize);
        for (uint256 i = 0; i < loanSize; i++) {
            data[i] = listSet.at(i);
        }
        return data;
    }

    /**
      * @dev Initiate an escrow swap
      @ @param _tokenId the good to swap
      */
    function swap(uint256 _tokenId) external {
        require(isListed(_tokenId), "Token ID is not listed");

        address seller = sellerOf[_tokenId];
        // solium-disable-next-line security/no-tx-origin
        address buyer = msg.sender;
        uint256 _price = priceOf[_tokenId];

        //send _price * taxRatio to seller
        //send _price *(1-taxRatio) to reward pool
        uint256 reward = _price.mul(taxRatio).div(100);
        uint256 giveDec = _price.mul(taxDev).div(100);
        uint256 giveSeller = _price.mul(100 - taxRatio - taxDev).div(100);

        require(
            erc20.transferFrom(buyer, rewardAddress, reward),
            "ERC20 transfer not successfully"
        );

        require(
            erc20.transferFrom(buyer, devAddress, giveDec),
            "ERC20 transfer not successfully"
        );

        require(
            erc20.transferFrom(buyer, seller, giveSeller),
            "ERC20 transfer not successfully"
        );
        _update(_tokenId, _price);

        erc721.transferFrom(address(this), buyer, _tokenId);

        removeListing(_tokenId);

        emit Swapped(buyer, seller, _tokenId, _price,hotpot.getGrade(_tokenId));
    }

    uint256 internal randomSeed = 1;

    function _update(uint256 _tokenId, uint256 _price) internal {
        uint256 supply = erc721.totalSupply();
        uint256 posibility = updatePosibility;
        if (supply < 11) {
            if (_price.div(10**18) < 100) {
                posibility = 0;
            }
        } else if (supply < 21) {
            if (_price.div(10**18) < 200) {
                posibility = 0;
            }
        } else if (supply < 51) {
            if (_price.div(10**18) < 400) {
                posibility = 0;
            }
        } else if (supply < 101) {
            if (_price.div(10**18) < 800) {
                posibility = 0;
            }
        } else if (supply < 201) {
            if (_price.div(10**18) < 1600) {
                posibility = 0;
            }
        } else if (supply < 501) {
            if (_price.div(10**18) < 3200) {
                posibility = 0;
            }
        } else {
            if (_price.div(10**18) < 6400) {
                posibility = 0;
            }
        }

        randomSeed += 2;
        //generate random number
        //it is not that safe
        uint256 random = uint256(
            sha256(abi.encodePacked(now, randomSeed++, msg.sender))
        ) % 100;

        if (random < posibility) {
            uint8 grade = hotpot.getGrade(_tokenId);
            if (grade < 3) {
                hotpot.update(_tokenId, grade + 1);
            }
        }
    }

    /**
     * @dev Unlist an item
     * @dev Can only be called by the item seller
     * @param _tokenId the item to unlist
     */
    function unlist(uint256 _tokenId) external {
        require(isListed(_tokenId), "Token ID is not listed");
        address seller = sellerOf[_tokenId];
        require(seller == msg.sender, "Sender is not seller");

        erc721.transferFrom(address(this), seller, _tokenId);

        removeListing(_tokenId);
    }

    /**
     * @dev List a good using a IERC721 receiver hook
     * @param _operator the caller of this function
     * @param _seller the good seller
     * @param _tokenId the good id to list
     * @param _data contains the pricing data as the first 32 bytes
     */
    function onERC721Received(
        address _operator,
        address _seller,
        uint256 _tokenId,
        bytes memory _data
    ) public override returns (bytes4) {
        require(_operator == _seller, "Seller must be operator");

        //Now the owner of token is this market contract!!
        require(
            erc721.ownerOf(_tokenId) == address(this),
            "onERC721Received can not be called directly!"
        );
        
        require(
            loan.checkCanSell(_tokenId, now),
            "This token is loaning!."
        );

        require(
            hotpot.getUseTime(_tokenId) + 86400 < now,
            "This token is charging."
        );

        uint256 _price = _data.toUint256(0);

        addListing(_seller, _tokenId, _price);

        return MAGIC_ON_ERC721_RECEIVED;
    }

    /**
     * @dev Determine whether an item is listed
     * @param _tokenId The id of the good to check
     * @return Return true if item is listed
     */
    function isListed(uint256 _tokenId) public view returns (bool) {
        return sellerOf[_tokenId] != address(0);
    }

    /**
     * @dev Convenience function to add token to listing
     * @param _seller the seller that is listing
     * @param _tokenId the token to add
     * @param _price the price
     */
    function addListing(
        address _seller,
        uint256 _tokenId,
        uint256 _price
    ) internal {
        require(_price > 0, "Price must be greater than zero");

        priceOf[_tokenId] = _price;
        sellerOf[_tokenId] = _seller;
        listSet.add(_tokenId);

        Reservation memory r = reservations[_tokenId];
        r.owner = _seller;
        r.price = _price;
        r.tokenId = _tokenId;
        reservations[_tokenId] = r;

        emit Listed(_seller, _tokenId, _price);
    }

    /**
     * @dev Convenience function to remove tokens from listing
     * @param _tokenId the token to remove
     */
    function removeListing(uint256 _tokenId) internal {
        address seller = sellerOf[_tokenId];

        delete priceOf[_tokenId];
        delete sellerOf[_tokenId];

        listSet.remove(_tokenId);

        delete reservations[_tokenId];

        emit Unlisted(seller, _tokenId);
    }
}
