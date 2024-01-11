// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC20BurnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";

contract YohToken is ERC20BurnableUpgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    uint256 public MAX_WALLET_STAKED;

    // 175 / 100 = 75%
    uint256 public MAX_MULTIPLIER;

    address nullAddress;
    address public yokaiAddress;
    address public yokaiOracle;

    //Mapping of yokai to timestamp
    mapping(uint256 => uint256) internal tokenIdToTimeStamp;
    //Mapping of yokai to staker
    mapping(uint256 => address) internal tokenIdToStaker;
    //Mapping of staker to yokai
    mapping(address => uint256[]) internal stakerToTokenIds;

    address public boostAddress;
    address public oracleVerification;
    uint256 public claimNonce;
    bool public pauseClaim;


    // Initializer function (replaces constructor)
    function initialize() public initializer {
        __ERC20_init("Yoh Token", "YOH");
        __ERC20Burnable_init();
        __Ownable_init();
        nullAddress = 0x0000000000000000000000000000000000000000;
        MAX_MULTIPLIER = 175;
        MAX_WALLET_STAKED = 100;
    }

    function setBoostAddress(address _boostAddress) public onlyOwner {
        boostAddress = _boostAddress;
    }

    function setPauseClaim(bool _pauseClaim) public onlyOwner {
        pauseClaim = _pauseClaim;
    }

    function setYokaiAddress(address _yokaiAddress, address _yokaiOracle) public onlyOwner {
        yokaiAddress = _yokaiAddress;
        yokaiOracle = _yokaiOracle;
    }

    function setMaxWalletStaked(uint256 _max_stake) public onlyOwner {
        MAX_WALLET_STAKED = _max_stake;
    }

    function setClaimNonce(uint256 _claimNonce) public onlyOwner {
        claimNonce = _claimNonce;
    }

    function setOracleVerification(address _oracleVerification) public onlyOwner {
        oracleVerification = _oracleVerification;
    }

    function stakeByIds(uint256[] memory tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                IERC721EnumerableUpgradeable(yokaiAddress).ownerOf(tokenIds[i]) == msg.sender &&
                    tokenIdToStaker[tokenIds[i]] == nullAddress,
                "Token must be stakable by you!"
            );

            IERC721EnumerableUpgradeable(yokaiAddress).transferFrom(msg.sender, address(this), tokenIds[i]);

            stakerToTokenIds[msg.sender].push(tokenIds[i]);

            tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
            tokenIdToStaker[tokenIds[i]] = msg.sender;
        }
    }

    // call this function in the event of newIds error calculation with unstakeByIds
    function saveIds(uint256[] memory tokenIds) public {
        for(uint i = 0; i < tokenIds.length; i++){
          require(tokenIdToStaker[tokenIds[i]] == msg.sender, "Cannot claim what is not yours!");
        }

        stakerToTokenIds[msg.sender] = tokenIds;
    }

    function unstakeByIds(uint256 totalRewards, uint256[] memory tokenIds, uint256[] memory newIds, bytes memory _signature) public {
        require(pauseClaim == false, "Unstaking is paused!");

        string memory _message = "";

        for(uint i = 0; i < tokenIds.length; i++){
          require(tokenIdToStaker[tokenIds[i]] == msg.sender, "Message Sender was not original staker!");
          IERC721EnumerableUpgradeable(yokaiAddress).transferFrom(address(this), msg.sender, tokenIds[i]);
          tokenIdToStaker[tokenIds[i]] = nullAddress;

          if(i == 0){
            _message = uint2str(tokenIds[i]);
          } else {
            _message = string(abi.encodePacked(_message,",",uint2str(tokenIds[i])));
          }
        }

        //sanity
        require(newIds.length == (stakerToTokenIds[msg.sender].length - tokenIds.length), "You might be missing a tokenId!");

        for(uint i = 0; i < newIds.length; i++){
          require(tokenIdToStaker[newIds[i]] == msg.sender, "Cannot claim what is not yours!");
        }

        stakerToTokenIds[msg.sender] = newIds;

        _message = string(abi.encodePacked(_message,",",uint2str(claimNonce),",",uint2str(totalRewards)));

        require(verify(_message, _signature) == oracleVerification, string(abi.encodePacked("claimAll: wrong message! ", _message)));

        claimNonce++;

        _mint(msg.sender, totalRewards);
    }

    function claimByTokenIds(uint256 totalRewards, uint256[] memory tokenIds, bytes memory _signature) public {
        require(pauseClaim == false, "Claiming is paused!");

        string memory _message = "";
        for(uint i = 0; i < tokenIds.length; i++){
          require(tokenIdToStaker[tokenIds[i]] == msg.sender, "Message Sender was not original staker!");

          if(i == 0){
            _message = uint2str(tokenIds[i]);
          } else {
            _message = string(abi.encodePacked(_message,",",uint2str(tokenIds[i])));
          }

          tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
        }

        _message = string(abi.encodePacked(_message,",",uint2str(claimNonce),",",uint2str(totalRewards)));

        require(verify(_message, _signature) == oracleVerification, string(abi.encodePacked("claimAll: wrong message! ", _message)));

        claimNonce++;

        _mint(msg.sender, totalRewards);
    }


    function splitSignature(bytes memory sig) internal pure returns (uint8, bytes32, bytes32){
        require(sig.length == 65);
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    // the output of this function will be the account number that signed the original message
    function verify(string memory message, bytes memory _signature) public pure returns (address) {
        bytes32 _ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(message))));
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }


    function getStaker(uint256 tokenId) public view returns (address) {
        return tokenIdToStaker[tokenId];
    }

    function getTokensStaked(address staker) public view returns (uint256[] memory) {
        return stakerToTokenIds[staker];
    }

    function getBoostBalance(address staker) public view returns (uint256 boostAmount) {
        boostAmount = 0;
        if(boostAddress != address(0)){
          boostAmount = IBoost(boostAddress).balanceOf(staker, 1);
        }
    }

    function getStakerInfo(address staker) public view returns (uint256[] memory tokenIds, uint256[] memory timestamps, uint256 boostAmount) {
        tokenIds = stakerToTokenIds[staker];
        uint256[] memory _timestamps = new uint256[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _timestamps[i] = tokenIdToTimeStamp[tokenIds[i]];
        }

        boostAmount = getBoostBalance(staker);

        timestamps = _timestamps;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

interface IBoost {
  function balanceOf(address account, uint256 id) external view  returns (uint256);
}

interface IERC721Enum {
  function tokensOfOwner(address owner) external view returns (uint256[] memory);
}
