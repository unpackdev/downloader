pragma solidity >=0.6.6;

interface IPublicPresale {
    function presaleOwner() external view returns (address);
    function availablePublicPresaleAmountOf(address account) external view returns (uint);

    function publicPresaleClaim(uint amount) external;
    function startPublicPresaleDistribution() external;
    function startPublicPresale() external;
}   