// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IMintable.sol";
import "./ERC20Burnable.sol";
import "./DestinationChainBridgeStorage.sol";
import "./SafeMathUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

contract DestinationChainBridge is DestinationChainBridgeStorage, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;

    uint256 private nonce; // Nonce for UUID generation
    bytes16 private constant hexAlphabet = "0123456789abcdef";

    event TokensLocked(address indexed user, uint256 amount, uint256 indexed bridgingId, address indexed tokenAddress, uint256 chainId);
    event BridgeCompleted(uint256 indexed bridgingId, uint256 indexed amount, address indexed tokenAddress, uint256 chainId);
    event TokensReleased(address indexed user, uint256 indexed amount, address indexed tokenAddress, string crossChainId);
    event OracleAddressChanged(address indexed oldAddress, address indexed newAddress);
    event FeePercentageChanged(uint256 indexed oldFeePercentage, uint256 indexed newFeePercentage);
    event AllowedBridgeTokensChanged(address indexed tokenAddress, bool indexed allowed);
    event AllowedChainsChanged(uint256 indexed chainId, bool indexed allowed);
    event FeeAmountReleased(uint256 indexed amount);

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Only oracle can call this");
        _;
    }

    function initialize(address _tokenAddress, address _oracleAddress, uint256 _feePercentage) initializer public {
        OwnableUpgradeable.__Ownable_init();
        allowedBridgeTokens[_tokenAddress] = true;
        oracleAddress = _oracleAddress;
        feePercentage = _feePercentage;
        isPaused = false;
    }

    function bridgeTokens(address _tokenAddress, uint256 _amount, uint256 _chainId) public nonReentrant {
        require(!isPaused, "Contract is paused");
        require(_tokenAddress != address(0), "Invalid token address");
        require(_amount > 0, "Amount must be greater than 0");
        require(IERC20(_tokenAddress).balanceOf(msg.sender) >= _amount, "Insufficient token balance");
        require(allowedChains[_chainId] == true, "Invalid chain id");
        require(allowedBridgeTokens[_tokenAddress] == true, "Invalid token address");

        uint256 id = allBridges.length;
        uint256 _feeAmount = _amount.mul(feePercentage).div(10000);

        string memory crossChainId = generateCrossChainId();

        allBridges.push(Bridge({
            id: id,
            user: msg.sender,
            tokenAddress: _tokenAddress,
            amount: _amount.sub(_feeAmount),
            isCompleted: false,
            chainId: _chainId,
            crossChainId: crossChainId,
            createDate: block.timestamp
        }));

        userBridgeIdsPerToken[msg.sender][_tokenAddress].push(id);
        allBridgesPerToken[_tokenAddress].push(id);

        ERC20Burnable(_tokenAddress).burnFrom(msg.sender, _amount.sub(_feeAmount));

        emit TokensLocked(msg.sender, _amount.sub(_feeAmount), id, _tokenAddress, _chainId);
    }

    function completeBridge(uint256 _bridgeId) public onlyOracle {
        require(allBridges[_bridgeId].user != address(0), "Bridging does not exist");
        require(allBridges[_bridgeId].tokenAddress != address(0) && allowedBridgeTokens[allBridges[_bridgeId].tokenAddress] == true, "Invalid token address");
        require(allBridges[_bridgeId].isCompleted == false, "Bridge already completed");

        allBridges[_bridgeId].isCompleted = true;

        emit BridgeCompleted(_bridgeId, allBridges[_bridgeId].amount, allBridges[_bridgeId].tokenAddress, allBridges[_bridgeId].chainId);
    }

    function releaseBridgedTokens(address _tokenAddress, address _user, uint256 _amount, string memory crossChainId) public onlyOracle {
        require(_tokenAddress != address(0) && allowedBridgeTokens[_tokenAddress] == true, "Invalid token address");
        require(_user != address(0), "Invalid user address");
        require(_amount > 0, "Invalid amount");
        require(executedBridgingCrossChainIds[crossChainId] == false, "Already executed");

        executedBridgingCrossChainIds[crossChainId] = true;

        IMintable(_tokenAddress).mintTo(_user, _amount);
        emit TokensReleased(_user, _amount, _tokenAddress, crossChainId);
    }

    function getAllPendingBridgesByToken(address _tokenAddress) public view returns (Bridge[] memory){
        require(_tokenAddress != address(0) && allowedBridgeTokens[_tokenAddress] == true, "Invalid token address");

        uint256[] memory tokenBridges = allBridgesPerToken[_tokenAddress];
        uint256 totalBridges = tokenBridges.length;
        Bridge[] memory pendingBridges = new Bridge[](totalBridges);
        uint256 count = 0;

        for (uint256 i = 0; i < totalBridges; i++) {
            if (!allBridges[tokenBridges[i]].isCompleted && allBridges[tokenBridges[i]].user != address(0)) {
                pendingBridges[count] = allBridges[tokenBridges[i]];
                count++;
            }
        }

        Bridge[] memory trimmedBridges = new Bridge[](count);
        for (uint256 i = 0; i < count; i++) {
            trimmedBridges[i] = pendingBridges[i];
        }

        return trimmedBridges;
    }

    function getAllUserPendingBridgesByToken(address _userWallet, address _tokenAddress) public view returns (Bridge[] memory) {
        require(_tokenAddress != address(0) && allowedBridgeTokens[_tokenAddress] == true, "Invalid token address");
        require(_userWallet != address(0), "Invalid user address");

        uint256[] memory userBridges = userBridgeIdsPerToken[_userWallet][_tokenAddress];
        uint256 totalBridges = userBridges.length;
        Bridge[] memory pendingBridges = new Bridge[](totalBridges);
        uint256 count = 0;

        for (uint256 i = 0; i < totalBridges; i++) {
            if (!allBridges[userBridges[i]].isCompleted && allBridges[userBridges[i]].user != address(0)) {
                pendingBridges[count] = allBridges[userBridges[i]];
                count++;
            }
        }

        Bridge[] memory trimmedBridges = new Bridge[](count);
        for (uint256 i = 0; i < count; i++) {
            trimmedBridges[i] = pendingBridges[i];
        }

        return trimmedBridges;
    }

    function getAllUserBridgesByToken(address _userWallet, address _tokenAddress) public view returns (Bridge[]memory){
        require(_tokenAddress != address(0) && allowedBridgeTokens[_tokenAddress] == true, "Invalid token address");
        require(_userWallet != address(0), "Invalid user address");

        uint256[] memory userBridges = userBridgeIdsPerToken[_userWallet][_tokenAddress];
        uint256 totalBridges = userBridges.length;
        Bridge[] memory allUserBridgesByToken = new Bridge[](totalBridges);

        for (uint256 i = 0; i < totalBridges; i++) {
            allUserBridgesByToken[i] = allBridges[userBridges[i]];
        }

        return allUserBridgesByToken;
    }


    function setOracleAddress(address _oracleAddress) public onlyOwner {
        require(_oracleAddress != address(0), "Invalid oracle address");
        oracleAddress = _oracleAddress;
        emit OracleAddressChanged(oracleAddress, _oracleAddress);
    }

    function setFeePercentage(uint256 _feePercentage) public onlyOwner {
        require(_feePercentage != feePercentage, "Already set");
        require(_feePercentage <= 10000, "Invalid fee percentage");

        feePercentage = _feePercentage;
        emit FeePercentageChanged(feePercentage, _feePercentage);
    }

    function setAllowedBridgeTokens(address _tokenAddress, bool _allowed) public onlyOwner {
        require(_tokenAddress != address(0), "Invalid token address");
        require(allowedBridgeTokens[_tokenAddress] != _allowed, "Already set");
        allowedBridgeTokens[_tokenAddress] = _allowed;
        emit AllowedBridgeTokensChanged(_tokenAddress, _allowed);
    }

    function setAllowedChains(uint256 _chainId, bool _allowed) public onlyOwner {
        require(allowedChains[_chainId] != _allowed, "Already set");
        allowedChains[_chainId] = _allowed;
        emit AllowedChainsChanged(_chainId, _allowed);
    }

    function releaseFeeAmount(address _tokenAddress) public onlyOwner {
        require(_tokenAddress != address(0), "Invalid token address");
        uint256 feeBalance = IERC20(_tokenAddress).balanceOf(address(this));
        require(feeBalance > 0, "No fee amount to release");
        require(IERC20(_tokenAddress).transfer(owner(), feeBalance), "Token transfer failed");

        emit FeeAmountReleased(feeBalance);
    }

    function getFeePercentage() public view returns (uint256){
        return feePercentage;
    }

    function isTokenAllowed(address _tokenAddress) public view returns (bool){
        return allowedBridgeTokens[_tokenAddress];
    }

    function isChainAllowed(uint256 _chainId) public view returns (bool){
        return allowedChains[_chainId];
    }

    function getOracleAddress() public view returns (address){
        return oracleAddress;
    }

    receive() external payable {}

    fallback() external payable {}

    function generateCrossChainId() private returns (string memory) {
        // generate a pseudo-unique string by hashing the current block's information, sender's address and a nonce
        nonce++;
        bytes32 uniqueIdHash = keccak256(abi.encodePacked(block.timestamp, address(this), nonce));
        return toHexString(uniqueIdHash);
    }

    function toHexString(bytes32 value) public pure returns (string memory) {
        // create a byte buffer array
        bytes memory buffer = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            // look up in a table and store the resultant in the buffer array
            buffer[i * 2] = hexAlphabet[uint8(value[i] >> 4)];
            buffer[1 + i * 2] = hexAlphabet[uint8(value[i] & 0x0f)];
        }

        return string(buffer);
    }

}
