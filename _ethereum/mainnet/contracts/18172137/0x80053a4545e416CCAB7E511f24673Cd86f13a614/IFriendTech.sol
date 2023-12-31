interface IFriendTech{    
    function sellShares(address sharesSubject, uint256 amount) external payable;

    function getBuyPrice(address sharesSubject, uint256 amount) external payable returns(uint256);

    function protocolFeePercent() external returns(uint256);
    
    function subjectFeePercent() external returns(uint256);

   
}