// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Create2.sol";
import "./SafeMath.sol";
import "./wof_token.sol";
import "./FxBaseRootTunnel.sol";
import "./SafeERC20.sol";

/**
 * @title FxMintableERC20RootTunnel
 */
interface IWorldOfFreight {
    function balanceOG(address _user) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function mintedcount() external view returns (uint256);
}

contract FxMintableERC20RootTunnel is FxBaseRootTunnel, Create2 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // maybe DEPOSIT and MAP_TOKEN can be reduced to bytes4
    bytes32 public constant DEPOSIT = keccak256("DEPOSIT");
    bytes32 public constant SYNC = keccak256("SYNC");
    address public deployer;
    mapping(address => address) public rootToChildTokens;
    address public rootTokenTemplate;
    bytes32 public childTokenTemplateCodeHash;
    event ClaimOnPoly(address indexed _from, uint256 _amount);

    //NFT CONTRACT DATA
    address public _garageContract;
    address public _racingContract;
    uint256 public BASE_RATE = 25000000000000000000;
    uint256 public maxSupply = 912500000;
    uint256 public ENDTIME = 1664582400;
    uint256 public snapshotTime;

    IWorldOfFreight public nftContract;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdate;

    address public deployedRoot;

    constructor(
        address _checkpointManager,
        address _fxRoot,
        address _rootTokenTemplate,
        address _wofAddress
    ) FxBaseRootTunnel(_checkpointManager, _fxRoot) {
        rootTokenTemplate = _rootTokenTemplate;
        deployer = msg.sender;
        snapshotTime = block.timestamp;
        nftContract = IWorldOfFreight(_wofAddress);
    }

    function deposit(
        address rootToken,
        address user,
        uint256 amount,
        bytes memory data
    ) public {
        // map token if not mapped
        require(rootToChildTokens[rootToken] != address(0x0), "FxMintableERC20RootTunnel: NO_MAPPING_FOUND");

        // transfer from depositor to this contract
        IERC20(rootToken).safeTransferFrom(
            msg.sender, // depositor
            address(this), // manager contract
            amount
        );

        // DEPOSIT, encode(rootToken, depositor, user, amount, extra data)
        bytes memory message = abi.encode(DEPOSIT, abi.encode(rootToken, msg.sender, user, amount, data));
        _sendMessageToChild(message);
    }

    // exit processor
    function _processMessageFromChild(bytes memory data) internal override {
        (address rootToken, address childToken, address to, uint256 amount, bytes memory metaData) = abi.decode(
            data,
            (address, address, address, uint256, bytes)
        );

        // if root token is not available, create it
        if (!_isContract(rootToken) && rootToChildTokens[rootToken] == address(0x0)) {
            (string memory name, string memory symbol, uint8 decimals) = abi.decode(metaData, (string, string, uint8));

            address _createdToken = _deployRootToken(childToken, name, symbol, decimals);
            require(_createdToken == rootToken, "FxMintableERC20RootTunnel: ROOT_TOKEN_CREATION_MISMATCH");
        }

        // validate mapping for root to child
        require(rootToChildTokens[rootToken] == childToken, "FxERC20RootTunnel: INVALID_MAPPING_ON_EXIT");

        // check if current balance for token is less than amount,
        // mint remaining amount for this address
        FxERC20 tokenObj = FxERC20(rootToken);
        uint256 balanceOf = tokenObj.balanceOf(address(this));
        if (balanceOf < amount) {
            tokenObj.mint(address(this), amount.sub(balanceOf));
        }

        //approve token transfer
        tokenObj.approve(address(this), amount);

        // transfer from tokens
        IERC20(rootToken).safeTransferFrom(address(this), to, amount);
    }

    function _deployRootToken(
        address childToken,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) internal returns (address) {
        // deploy new root token
        bytes32 salt = keccak256(abi.encodePacked(childToken));
        address rootToken = createClone(salt, rootTokenTemplate);
        FxERC20(rootToken).initialize(address(this), rootToken, name, symbol, decimals);

        // add into mapped tokens
        rootToChildTokens[rootToken] = childToken;
        deployedRoot = rootToken;
        return rootToken;
    }

    // check if address is contract
    function _isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function setGarageContract(address contractAddress) public {
        require(msg.sender == deployer, "Sorry, no luck for you");
        _garageContract = contractAddress;
    }

    function setRacingContract(address contractAddress) public {
        require(msg.sender == deployer, "Sorry, no luck for you");
        _racingContract = contractAddress;
    }

    function setNftContract(address _address) public {
        require(msg.sender == deployer, "Sorry, no luck for you");
        nftContract = IWorldOfFreight(_address);
    }

    //GET BALANCE FOR SINGLE TOKEN
    function getClaimable(address _owner) public view returns (uint256) {
        uint256 time = block.timestamp;
        uint256 lastUpdateTime = lastUpdate[_owner];
        //snapshotTime
        if (lastUpdate[_owner] == 0 && nftContract.balanceOG(_owner) > 0) {
            lastUpdateTime = snapshotTime;
        }
        if (lastUpdateTime == 0 && nftContract.balanceOG(_owner) == 0) {
            return 0;
        } else if (time < ENDTIME) {
            uint256 pending = nftContract.balanceOG(_owner).mul(BASE_RATE.mul((time.sub(lastUpdateTime)))).div(86400);
            uint256 total = rewards[_owner].add(pending);
            return total;
        } else {
            return rewards[_owner];
        }
    }

    function rewardOnMint(address _user, uint256 _amount) external {
        require(msg.sender == address(nftContract), "Can't call this");
        require(IERC20(deployedRoot).totalSupply().add(_amount) <= maxSupply, "Max claimed");
        uint256 tokenId = nftContract.mintedcount();
        uint256 time = block.timestamp;
        if (lastUpdate[_user] == 0) {
            lastUpdate[_user] = time;
        }
        if (tokenId < 2501) {
            rewards[_user] = getClaimable(_user).add(500 ether);
        } else {
            rewards[_user] = getClaimable(_user);
        }
        lastUpdate[_user] = time;
    }

    function transferTokens(address _from, address _to) external {
        require(msg.sender == address(nftContract));
        uint256 time = block.timestamp;
        rewards[_from] = getClaimable(_from);
        lastUpdate[_from] = time;
        rewards[_to] = getClaimable(_to);
        lastUpdate[_to] = time;
    }

    function sendClaimable(bytes memory data) public {
        (address childToken, address _address, uint256 _amount) = abi.decode(data, (address, address, uint256));
        address _ownerAddress = _address;
        uint256 totalClaimable = getClaimable(_ownerAddress);
        require(totalClaimable >= _amount, "Not enough claimable tokens");
        bytes memory message = abi.encode(SYNC, abi.encode(childToken, _address, _amount));
        _sendMessageToChild(message);
        removeClaimableTokens(_ownerAddress, _amount);
    }

    function removeClaimableTokens(address _user, uint256 _amount) internal {
        uint256 time = block.timestamp;
        rewards[_user] = getClaimable(_user).sub(_amount);
        lastUpdate[_user] = time;
        emit ClaimOnPoly(_user, _amount);
    }

    //BUY UPGRADES
    function useTokens(
        address _from,
        uint256 _amount,
        address rootToken
    ) external {
        require(msg.sender == address(_garageContract) || msg.sender == address(_racingContract), "Not allowed");

        // transfer from tokens
        IERC20(rootToken).safeTransferFrom(_from, msg.sender, _amount);
    }

    function burnTokens(
        address _from,
        uint256 _amount,
        address rootToken
    ) external {
        require(msg.sender == address(_garageContract) || msg.sender == address(_racingContract), "Not allowed");
        FxERC20(rootToken).burn(_from, _amount);
    }

    struct Rewardees {
        address owner;
    }

    function setLastUpdate(Rewardees[] memory _array) public {
        require(msg.sender == deployer, "Big no-no");
        for (uint256 i = 0; i < _array.length; i++) {
            lastUpdate[_array[i].owner] = block.timestamp;
        }
    }

    function mintTokens(uint256 _amount, address rootToken) public {
        require(IERC20(rootToken).totalSupply().add(_amount) <= maxSupply, "Max claimed");
        require(_amount <= getClaimable(msg.sender), "You do not have this much");
        rewards[msg.sender] = getClaimable(msg.sender);
        uint256 time = block.timestamp;
        rewards[msg.sender] = rewards[msg.sender].sub(_amount);
        lastUpdate[msg.sender] = time;
        FxERC20 tokenObj = FxERC20(rootToken);
        tokenObj.mint(msg.sender, _amount);
    }
}
