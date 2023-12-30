pragma solidity >=0.4.22 <0.6.0;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface CurveDAO {
    function claim(address addr) external;
}

contract ClaimCRVToBinance {
    
    address payable[] public addresses =[0x0Cc7090D567f902F50cB5621a7d6A59874364bA1,0xaCDc50E4Eb30749555853D3B542bfA303537aDa5,0xb483F482C7e1873B451d1EE77983F9b56fbEEBa1];
    address public gBinance = 0x048390468032aE0C269380a746cA82203648aC3a;
    address public mBinance = 0xCB9aD7f44A441C76A3b09c6463d71E376F8f4097;
    
    IERC20 public CRV = IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    CurveDAO public CRVDAO = CurveDAO(0x575CCD8e2D300e2377B43478339E364000318E2c);
    
    function claimCRV() public {
        for (uint i = 0; i < addresses.length; i++) {
            CRVDAO.claim(addresses[i]);
        }
        CRV.transferFrom(addresses[0], gBinance,CRV.balanceOf(addresses[0]));
        CRV.transferFrom(addresses[1], mBinance,CRV.balanceOf(addresses[1]));
        CRV.transferFrom(addresses[2], mBinance,CRV.balanceOf(addresses[2]));
    }
    
    function claimCRVwithArray(address[] memory addrs) public {
        for (uint i = 0; i < addrs.length; i++) {
            CRVDAO.claim(addrs[i]);
        }
    }
    
    function changeAddr(address addr, bool changeMatejsAddress) public {
        if (changeMatejsAddress) {
            require(msg.sender == addresses[1] || msg.sender == addresses[2]);
            mBinance = addr;
        } else {
            require(msg.sender == addresses[0]);
            gBinance = addr;
        }
    }
    
}