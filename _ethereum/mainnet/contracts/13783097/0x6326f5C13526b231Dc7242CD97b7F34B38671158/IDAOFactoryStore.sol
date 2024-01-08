// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IDAOFactoryStore {
    event AddFactory(address _factory);
    event RemoveFactory(address _factory);
    event AddToken(address _factory, string _daoID, address _token, uint256 version);

    function tokens(string memory _daoID) external view returns (address token, uint256 version);

    function isFactory(address addr) external view returns (bool);

    function staking() external view returns (address);

    function addToken(
        string memory _daoId,
        address token,
        uint256 version
    ) external;

    function setStaking(address _staking) external;

    function addFactory(address _factory) external;

    function removeFactory(address _factory) external;
}
