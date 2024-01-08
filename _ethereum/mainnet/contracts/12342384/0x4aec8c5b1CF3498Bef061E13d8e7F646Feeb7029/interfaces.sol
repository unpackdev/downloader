pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface IndexInterface {
    function build(
        address _owner,
        uint accountVersion,
        address _origin
    ) external returns (address _account);

    function buildWithCast(
        address _owner,
        uint accountVersion,
        string[] calldata _targets,
        bytes[] calldata _datas,
        address _origin
    ) external payable returns (address _account);
}

interface ManagerLike {
    function owns(uint) external view returns (address);
    function give(uint, address) external;
}