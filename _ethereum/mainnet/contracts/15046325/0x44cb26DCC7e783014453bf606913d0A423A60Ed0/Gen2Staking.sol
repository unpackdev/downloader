//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./draft-EIP712Upgradeable.sol";
import "./Initializable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./ECDSA.sol";
import "./IFaction.sol";
import "./IERC721A.sol";
import "./IStaked.sol";
import "./IGen2.sol";
import "./RequestManagerUpgradeable.sol";

contract Gen2Staking is Initializable, PausableUpgradeable, ReentrancyGuardUpgradeable, RequestManagerUpgradeable, IERC721ReceiverUpgradeable {
    IERC721A public genOne;

    event GenOneStaked(address owner, uint256 id);
    event GenTwoStaked(address owner, uint256 id);
    event GenOneUnStaked(address owner, uint256 id);
    event GenTwoUnStaked(address owner, uint256 id);

    function changeGenOne(IERC721A _genOne) external onlyAdmins {
        genOne = _genOne;
    }

    IGen2 public genTwo;

    function changeGenTwo(IGen2 _genTwo) external onlyAdmins {
        genTwo = _genTwo;
    }

    IStaked public genOneStaked;

    function changeGenOneStaked(IStaked _genOneStaked) external onlyAdmins {
        genOneStaked = _genOneStaked;
    }

    IStaked public genTwoStaked;

    function changeGenTwoStaked(IStaked _genTwoStaked) external onlyAdmins {
        genTwoStaked = _genTwoStaked;
    }

    mapping(uint256 => uint256) private _tokenToTimestamp;

    function initialize(IAdmins admins, IERC721A _genOne, IGen2 _genTwo, address _signer, IStaked _genOneStaked, IStaked _genTwoStaked) public initializer {
        __Pausable_init();
        __ReentrancyGuard_init();        
        __RequestManager_init(_signer, admins);
        genOne = _genOne;
        genTwo = _genTwo;
        genOneStaked = _genOneStaked;
        genTwoStaked = _genTwoStaked;
    }

    function stake(StakeRequest calldata request, bytes calldata signature) external whenNotPaused nonReentrant {
        require(verifyStake(request, signature), "Invalid signature");
        uint256[] memory genOnes = request.genOnes;
        uint256[] memory genTwos = request.genTwos;

        uint256 noGenOnes = genOnes.length;
        uint256 noGenTwos = genTwos.length;

        for(uint256 i; i < noGenOnes;) {
            uint256 current = genOnes[i];
            require(genOne.ownerOf(current) == msg.sender, "Not owner");            
            genOne.safeTransferFrom(msg.sender, address(this), current);                        
            emit GenOneStaked(msg.sender, current);
            unchecked {
                ++i;
            }
        }

        for(uint256 i; i < noGenTwos;) {
            uint256 current = genTwos[i];
            require(genTwo.ownerOf(current) == msg.sender, "Not owner"); 
            genTwo.safeTransferFrom(msg.sender, address(this), current);
            _tokenToTimestamp[current] = block.timestamp;
            emit GenTwoStaked(msg.sender, current);
            unchecked {
                ++i;
            }
        }

        if(noGenOnes > 0) genOneStaked.mint(genOnes, request.genOnesAmount, msg.sender);
        if(noGenTwos > 0) genTwoStaked.mint(genTwos, request.genTwosAmount, msg.sender);
    }

    function unstake(UnstakeRequest calldata request, bytes calldata signature) external whenNotPaused nonReentrant {
        require(verifyUnstake(request, signature), "Invalid signature");
        uint256[] memory exps = request.exps;
        uint256[] memory genOnes = request.genOnes;
        uint256[] memory genTwos = request.genTwos;

        uint256 noGenOnes = genOnes.length;
        uint256 noGenTwos = genTwos.length;

        for(uint256 i; i < noGenOnes;) {
            uint256 current = genOnes[i];
            require(genOneStaked.balanceOf(msg.sender, current) == 1, "Not owner");
            genOne.safeTransferFrom(address(this), msg.sender, current);
            emit GenOneUnStaked(msg.sender, current);
            unchecked {
                ++i;
            }
        }

        for(uint256 i; i < noGenTwos;) {
            uint256 current = genTwos[i];
            require(genTwoStaked.balanceOf(msg.sender, current) == 1, "Not owner");            
            _claim(current, exps[i]);
            delete _tokenToTimestamp[current];
            genTwo.safeTransferFrom(address(this), msg.sender, current);
            emit GenTwoUnStaked(msg.sender, current);
            unchecked {
                ++i;
            }
        }

        if(noGenOnes > 0) genOneStaked.burn(genOnes, request.genOnesAmount, msg.sender);
        if(noGenTwos > 0) genTwoStaked.burn(genTwos, request.genTwosAmount, msg.sender);
    }

    function _claim(uint256 id, uint256 exp) internal {
        _tokenToTimestamp[id] = block.timestamp;
        genTwo.mutateLevel(id, exp);
    }

    function claim(ClaimRequest calldata request, bytes calldata signature) external whenNotPaused nonReentrant {
        require(verifyClaim(request, signature), "Invalid signature");
        uint256[] memory exps = request.exps;
        uint256[] memory genTwos = request.genTwos;

        uint256 noGenTwos = genTwos.length;
        
        for(uint256 i; i < noGenTwos;) {
            uint256 current = genTwos[i];
            require(genTwoStaked.balanceOf(msg.sender, current) == 1, "Not owner");
            _claim(current, exps[i]);
            unchecked {
                ++i;
            }
        }
    }

    function delta(uint256 id) external view returns (uint256) {
        if(_tokenToTimestamp[id] == 0) return 0;
        return block.timestamp - _tokenToTimestamp[id];
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata 
    ) external pure override(IERC721ReceiverUpgradeable) returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }
}