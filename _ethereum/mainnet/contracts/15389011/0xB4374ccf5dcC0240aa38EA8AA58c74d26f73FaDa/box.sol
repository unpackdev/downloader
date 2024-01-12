//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ECDSA.sol";
import "./IERC20.sol";
import "./IERC721.sol";

contract BlindBox is ERC1155, Ownable, Pausable {
    using SafeMath for uint256;

    IERC20 public swapToken = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    string public name;
    string public symbol;
    string public baseURL;

    uint8 public levels = 3;
    bool public openLevel;

    struct Box {
        uint    id;
        string  name;
        uint    price;
        uint256 startTokenId;
        address birthNFT;
        uint256 mintNum;
        uint256 openNum;
        uint256 totalSupply;
        bool    status;
    }

    struct User {
        uint id;
        address referrer;
        uint partnersCount;
    }
    mapping(address => User) public users;
    mapping(uint => address) public userIds;
    uint public latestUserId = 2;

    mapping(uint => Box) public boxMap;
    mapping(uint8 => uint256) public levelRate;
    uint256 public constant levelDenominator = 100;

    mapping(address => bool) public adminRegistration;

    modifier onlyAdminRegistration() {
        require(adminRegistration[_msgSender()], "Mint: caller is not the minter");
        _;
    }

    address public receiverU = address(0xa0A92b06B128440adC15841DD7D76C1375D222af);

    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event OpenBox(address indexed user, uint boxId, uint tokenId);

    constructor(string memory url_) ERC1155(url_) {
        name = "Lost Land Box";
        symbol = "LLBOX";
        baseURL = url_;
        levelRate[1] = 10;
        levelRate[2] = 3;
        levelRate[3] = 2;
        openLevel = true;
        adminRegistration[_msgSender()] = true;
    }

    function newBox(uint boxId_, string memory name_, uint256 price_, uint256 startTokenId_, address birthNFT_, uint256 totalSupply_) public onlyOwner {
        require(boxId_ > 0 && boxMap[boxId_].id == 0, "box id invalid");
        boxMap[boxId_] = Box({
            id: boxId_,
            name: name_,
            price: price_,
            startTokenId: startTokenId_,
            birthNFT: birthNFT_,
            mintNum: 0,
            openNum: 0,
            totalSupply: totalSupply_,
            status: true
        });
    }

    function updateBox(uint boxId_, address birthNFT_, uint256 price_, uint256 totalSupply_, uint256 startTokenId_, bool status_) public onlyOwner {
        require(boxId_ > 0, "id invalid");
        require(totalSupply_ >= boxMap[boxId_].mintNum && price_ > 0, "totalSupply or price err");

        boxMap[boxId_].birthNFT = birthNFT_;
        boxMap[boxId_].totalSupply = totalSupply_;
        boxMap[boxId_].startTokenId = startTokenId_;
        boxMap[boxId_].price = price_;
        boxMap[boxId_].status = status_;
    }

    function registration(address userAddress, address referrerAddress) private {
        require(!isReferrerExists(userAddress) && userAddress != referrerAddress, "referrer exists");
        address userTemp = referrerAddress;
        for (uint8 i=1; i <= levels; i++) {
            require(users[userTemp].referrer != userAddress, "invalid referrer");
            userTemp = users[referrerAddress].referrer;
        }

        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");

        User memory user = User({
            id: latestUserId,
            referrer: referrerAddress,
            partnersCount: 0
        });

        users[userAddress] = user;
        userIds[latestUserId] = userAddress;
        latestUserId++;

        users[referrerAddress].partnersCount++;

        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }

    function isReferrerExists(address user) public view returns (bool) {
        return (users[user].referrer != address(0));
    }

    function buyBox(uint boxId_, uint num_, address referrer_) public whenNotPaused {
        require(boxMap[boxId_].id != 0 && boxMap[boxId_].status, "box id or status err");
        if (referrer_ != address(0) && !isReferrerExists(_msgSender()))  {
            registration(_msgSender(), referrer_);
        }
        uint allPrice = boxMap[boxId_].price * num_;

        require(swapToken.balanceOf(_msgSender()) >= allPrice, "Insufficient balance");
        if (openLevel && isReferrerExists(_msgSender())) {
            address user = _msgSender();
            uint256 allBonus = 0;
            for (uint8 i=1; i <= levels; i++) {
                if (users[user].referrer == address(0)) { break; }
                user = users[user].referrer;
                uint256 bonus = allPrice.mul(levelRate[i]).div(levelDenominator);
                allBonus += bonus;
                swapToken.transferFrom(_msgSender(), user, bonus);
            }
            allPrice -= allBonus;
        }
        swapToken.transferFrom(_msgSender(), receiverU, allPrice);
        mint(_msgSender(), boxId_, num_);
    }

    function AdminBox(uint boxId_, uint num_) public onlyOwner {
        require(boxMap[boxId_].id != 0, "box id or num err");
        mint(_msgSender(), boxId_, num_);
    }

    function openBox(uint boxId_) public returns (bool) {
        _burn(_msgSender(), boxId_, 1);
        boxMap[boxId_].openNum += 1;
        IERC721(boxMap[boxId_].birthNFT).mint(_msgSender(), boxMap[boxId_].startTokenId);
        emit OpenBox(_msgSender(), boxId_, boxMap[boxId_].startTokenId);
        boxMap[boxId_].startTokenId++;
        return true;
    }

    function mint(address to_, uint boxId_, uint num_) private returns (bool) {
        require(num_ > 0, "mint number err");
        require(boxMap[boxId_].id != 0, "box id err");
        require(boxMap[boxId_].totalSupply >= boxMap[boxId_].mintNum + num_, "mint number is insufficient");
        boxMap[boxId_].mintNum += num_;
        _mint(to_, boxId_, num_, "");
        return true;
    }

    function uri(uint boxId_) public view override returns (string memory) {
        return string(abi.encodePacked(baseURL, Strings.toString(boxId_)));
    }

    function setLevelRate(uint256 rate1_, uint256 rate2_, uint256 rate3_) public onlyOwner {
        require(rate1_+rate2_+rate3_ < 100, "rate err");
        levelRate[1] = rate1_;
        levelRate[2] = rate2_;
        levelRate[3] = rate3_;
    }

    function setLevels(uint8 levels_) public onlyOwner {
        levels = levels_;
    }

    function setPause(bool isPause) public onlyOwner {
        if (isPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setOpenLevel(bool open_) public onlyOwner {
        openLevel = open_;
    }

    function setAdminRegistration(address admin_, bool status) public onlyOwner {
        adminRegistration[admin_] = status;
    }

    function setRegistration(address userAddress, address referrerAddress) public onlyAdminRegistration {
        registration(userAddress, referrerAddress);
    }

    function getUserReferrer(address user_) public view returns (address) {
        return users[user_].referrer;
    }

    function setURI(string memory uri_) public onlyOwner {
        baseURL = uri_;
    }

    function setReceiverU(address receiverU_) public onlyOwner {
        receiverU = receiverU_;
    }
    
    function setSwapToken(address addr_) public onlyOwner {
        swapToken = IERC20(addr_);
    }
}
