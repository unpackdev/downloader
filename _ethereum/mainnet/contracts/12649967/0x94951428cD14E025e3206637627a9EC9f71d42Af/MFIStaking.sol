import "./TokenStaking.sol";

contract MFIStaking is TokenStaking {
    constructor(address _MFI, address _roles)
        TokenStaking(_MFI, _MFI, _roles)
    {}
}
