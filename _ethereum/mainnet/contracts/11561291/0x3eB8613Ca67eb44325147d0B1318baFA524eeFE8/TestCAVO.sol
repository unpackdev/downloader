pragma solidity >=0.6.6;

import "./PublicPresale.sol";
import "./TeamDistribution.sol";
import "./PrivatePresale.sol";
import "./TestxCAVO.sol";
import "./TestEXCV.sol";

contract TestCAVO is PublicPresale, PrivatePresale, TeamDistribution {

    uint public constant PUBLIC_PRESALE_DURATION_IN_BLOCKS = 10;
    uint32 public constant PRESALE_VESTING_PERIOD_IN_BLOCKS = 10;
    uint public constant PRIVATE_PRESALE_DISTRIBUTED_CAVO_IN_WEI = 10000;
    address private constant PUBLIC_PRESALE_OWNER = 0xeAD9C93b79Ae7C1591b1FB5323BD777E86e150d4;
    address[] private _teamAddresses = [
        0xeAD9C93b79Ae7C1591b1FB5323BD777E86e150d4, 
        0xE5904695748fe4A84b40b3fc79De2277660BD1D3, 
        0x92561F28Ec438Ee9831D00D1D59fbDC981b762b2
    ];
    uint[] private _teamAmounts = [
        1000000,
        1500000,
        2000000
    ];

    constructor() 
        public 
        PublicPresale(PUBLIC_PRESALE_OWNER, PRESALE_VESTING_PERIOD_IN_BLOCKS, PUBLIC_PRESALE_DURATION_IN_BLOCKS) 
        PrivatePresale(PRESALE_VESTING_PERIOD_IN_BLOCKS, PRIVATE_PRESALE_DISTRIBUTED_CAVO_IN_WEI) 
        TeamDistribution(PRESALE_VESTING_PERIOD_IN_BLOCKS, _teamAddresses, _teamAmounts) 
    {
        address _xCAVO;
        address _EXCV;
        bytes memory xCAVOBytecode = type(TestxCAVO).creationCode;
        bytes memory EXCVBytecode = type(TestEXCV).creationCode;
        bytes32 xCAVOSalt = keccak256(abi.encodePacked("xCAVO"));
        bytes32 EXCVSalt = keccak256(abi.encodePacked("EXCV"));
        assembly {
            _xCAVO := create2(0, add(xCAVOBytecode, 32), mload(xCAVOBytecode), xCAVOSalt)
            _EXCV := create2(0, add(EXCVBytecode, 32), mload(EXCVBytecode), EXCVSalt)
        }
        xCAVOToken = _xCAVO;
        EXCVToken = _EXCV;

        _mint(address(this), totalTeamDistribution.add(totalPrivatePresaleDistribution));
    }

    function teamAddresses() external view returns (address[] memory) {
        return _teamAddresses;
    }

    function teamAmounts() external view returns (uint[] memory) {
        return _teamAmounts;
    }

    function testMint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}