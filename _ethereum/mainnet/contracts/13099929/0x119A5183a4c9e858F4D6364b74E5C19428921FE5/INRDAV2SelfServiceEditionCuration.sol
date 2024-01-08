pragma solidity 0.6.12;

interface INRDAV2SelfServiceEditionCuration {

  function createEdition(
    uint256 _editionNumber,
    bytes32 _editionData,
    uint256 _editionType,
    uint256 _startDate,
    uint256 _endDate,
    address _artistAccount,
    uint256 _artistCommission,
    uint256 _priceInWei,
    string memory _tokenUri,
    uint256 _totalAvailable,
    bool _active
  ) external returns (bool);

  function artistsEditions(address _artistsAccount) external returns (uint256[1] memory _editionNumbers);

  function totalAvailableEdition(uint256 _editionNumber) external returns (uint256);

  function highestEditionNumber() external returns (uint256);

  function updateOptionalCommission(uint256 _editionNumber, uint256 _rate, address _recipient) external;

  function updateStartDate(uint256 _editionNumber, uint256 _startDate) external;

  function updateEndDate(uint256 _editionNumber, uint256 _endDate) external;

  function updateEditionType(uint256 _editionNumber, uint256 _editionType) external;
}
