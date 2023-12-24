// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

import "./IERC165.sol";
import "./ILayerZeroEndpointV2.sol";
import "./MessagingStructs.sol";

interface IMessageLib is IERC165 {
    function send(
        Packet calldata _packet,
        bytes calldata _options,
        bool _payInLzToken
    ) external returns (MessagingFee memory, bytes memory encodedPacket);

    function quote(
        PacketForQuote calldata _packet,
        bool _payInLzToken,
        bytes calldata _options
    ) external view returns (MessagingFee memory);

    function setTreasury(address _treasury) external;

    function setConfig(address _oapp, uint32 _eid, SetConfigParam[] calldata _config) external;

    function snapshotConfig(uint32[] calldata _eids, address _oapp) external;

    function resetConfig(uint32[] calldata _eids, address _oapp) external;

    function getConfig(
        uint32 _eid,
        address _oapp,
        uint32 _configType
    ) external view returns (bytes memory config, bool isDefault);

    function getDefaultConfig(uint32 _eid, uint32 _configType) external view returns (bytes memory);

    function isSupportedEid(uint32 _eid) external view returns (bool);

    function withdrawFee(address _to, uint _amount) external;

    function withdrawLzTokenFee(address _lzToken, address _to, uint _amount) external;

    // message libs of same major version are compatible
    function version() external view returns (uint64 major, uint8 minor, uint8 endpointVersion);
}
