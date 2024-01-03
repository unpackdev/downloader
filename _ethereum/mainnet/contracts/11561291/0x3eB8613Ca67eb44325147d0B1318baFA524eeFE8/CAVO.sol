pragma solidity >=0.6.6;

import "./PublicPresale.sol";
import "./xCAVO.sol";
import "./EXCV.sol";
import "./TeamDistribution.sol";
import "./PrivatePresale.sol";

contract CAVO is PublicPresale, PrivatePresale, TeamDistribution {
    
    uint private constant PUBLIC_PRESALE_DURATION_IN_BLOCKS = 7 * 6500;
    uint32 private constant PRESALE_VESTING_PERIOD_IN_BLOCKS = 7 * 6500;
    
    uint private constant PRIVATE_PRESALE_DISTRIBUTED_CAVO_IN_WEI = 1460.769 ether;
    
    address private constant PUBLIC_PRESALE_OWNER = 0xAb96C12881A2E9Ffa6706Ae68bCFA4EcD1A8bf21;

    address[] private teamAddresses = [
        0x381657fdE9bfE7558837757aC54249Ef748CACB7, // A.M.
        0x564569020c298D2487445CCa5C5ef3eD8cd408A3, // Y.O.
        0xDfe2abc3d395a87a1476f5B707E77f5F23B1d88b, // A.
        0x8CF3329E378c6196F35f5cB7eea5040873f8AC8C, // D.B.
        0x8B9a2b2d9a41909D613C81F2f344E364cD62b63C, // Z.
        0x57B93A6b8954938DE455BE95c9AA7843b99D7DEa, // V.
        0xf0393FB1e988317ca6E3fb986874D019dE712c7d, // M.
        0x698f4a1f42c3601579A3E40a9e4D90C2032C443a  // X.
    ];

    uint[] private teamAmounts = [
        40000 ether, // A.M.
        40000 ether, // Y.O.
        15000 ether, // A.
        10000 ether, // D.B.
        50000 ether, // Z.
        30000 ether, // V.
        10000 ether, // M.
        5000  ether  // X.
    ];
    
    constructor() 
        public 
        PublicPresale(PUBLIC_PRESALE_OWNER, PRESALE_VESTING_PERIOD_IN_BLOCKS, PUBLIC_PRESALE_DURATION_IN_BLOCKS) 
        PrivatePresale(PRESALE_VESTING_PERIOD_IN_BLOCKS, PRIVATE_PRESALE_DISTRIBUTED_CAVO_IN_WEI) 
        TeamDistribution(PRESALE_VESTING_PERIOD_IN_BLOCKS, teamAddresses, teamAmounts) 
    {
        address _xCAVO;
        address _EXCV;
        bytes memory xCAVOBytecode = type(xCAVO).creationCode;
        bytes memory EXCVBytecode = type(EXCV).creationCode;
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
}
