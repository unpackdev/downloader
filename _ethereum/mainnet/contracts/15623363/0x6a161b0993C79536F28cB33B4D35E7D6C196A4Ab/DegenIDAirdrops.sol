// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

/**
              :~7J5PGGGGGGGGGGGGGGG^  JGGGGGGG^ :GGGGPPY?!^.                            
          .!5B&DIDDIDDIDDIDDIDDIDID~  PDIDDIDD^ ^DIDDIDDIDD#GJ^                         
        :Y#DIDDIDDIDDIDDIDDIDDIDDID~  PDIDDIDD^ ^DIDDIDDIDDIDIDG7                       
       ?&DIDDIDID&BPYJJJJJJBDIDDIDD~  !JJJJJJJ: .JJJY5G#DIDDIDDIDG^                     
      YDIDDIDIDP!:         PDIDDIDD~                   .^J#DIDDIDD&~                    
     ?DIDDIDD&!            PDIDDIDD~  JGPPPPGG^           .5DIDDIDD#.                   
    .BDIDDIDD!             PDIDDIDD~  PDIDDIDD~             PDIDDIDD?                   
    ^&DIDDIDB.             PDIDDIDD~  PDIDDIDD~             7DIDDIDD5                   
    :&DIDDID#.             PDIDDIDD~  PDIDDIDD~             ?DIDDIDD5                   
     GDIDDIDDJ             PDIDDIDD~  PDIDDIDD~            .BDIDDIDD7                   
     ~DIDDIDIDY.           !???????:  PDIDDIDD~           ~BDIDDIDDP                    
      7DIDDIDID&5!^.                  PDIDDIDD~      .:~?GDIDDIDIDG.                    
       ^GDIDDIDDIDD#BGGGGGGGGGGGGGG^  PDIDDIDDBGGGGGB#&DIDDIDDID&J.                     
         !P&DIDDIDDIDDIDDIDDIDDIDID~  PDIDDIDDIDDIDDIDDIDDIDID#J:                       
           :7YG#DIDDIDDIDDIDDIDDIDD~  PDIDDIDDIDDIDDIDDID&#PJ~.                         
               .^~!??JJJJJJJJJJJJJJ:  !JJJJJJJJJJJJJJ?7!^:.                             
                                                                                                   
**/

contract DegenIDAirdrops is EIP712, Ownable, Pausable {
    using SafeERC20 for IERC20;
	using SafeMath for uint256;

    event OtherTokensWithdrawn(address indexed currency, uint256 amount);
	event Airdropped(address receiver, uint256 amount);

	string private constant SIGNING_DOMAIN = "DegenID Token Airdrops";
	string private constant SIGNING_DOMAIN_VERSION = "1";
	address private cSigner = 0xAD46c8a34c7516F273Db35f260AEedf3303625d4;
	address public DIDRegister;
	bool private canClaim = false;
    uint256 public AirdropRound;
    IERC20 public DegenIDToken;

    mapping(uint256=>mapping(bytes32=>bool)) private ifSecretUsed;
	mapping(address=>bool) public ifRegistered;

	struct AirdropCallData {
		address owner;
        uint256 amount;
        uint256 round;
        bytes32 secret;
		bytes signature;
	}

	constructor(address _tokenAddr) EIP712(SIGNING_DOMAIN, SIGNING_DOMAIN_VERSION) {
        AirdropRound = 1;
        DegenIDToken = IERC20(_tokenAddr);
    }

	function getChainID() external view returns (uint256) {
		uint256 id;
		assembly {
			id := chainid()
		}
		return id;
	}

	function setDIDRegister(address _addr) public onlyOwner {
		DIDRegister = _addr;
	}

	function markRegistered(address register) external {
		require(msg.sender == DIDRegister || msg.sender == owner(), "Unauthorized");
		if(!ifRegistered[register]) {
			ifRegistered[register] = true;
		}
		
	}

    function airdropQuota() external view returns(uint256) {
        return DegenIDToken.balanceOf(address(this));
    }

	function encodeArray(uint256[][] memory arr) external pure returns (bytes32){
		return keccak256(abi.encode(arr));
	}

	function _hashAirdropCallData(AirdropCallData calldata data) internal view returns (bytes32) {
		return _hashTypedDataV4(keccak256(abi.encode(
			keccak256("AirdropCallData(address owner,uint256 amount,uint256 round,bytes32 secret)"),
			data.owner,
			data.amount,
			data.round,
			data.secret
		)));
	}

	function isAirdropCallDataValid(AirdropCallData calldata data) public view returns(bool){
		return ECDSA.recover(_hashAirdropCallData(data), data.signature) == cSigner;
	}

	function checkSigner(AirdropCallData calldata data) public view returns(address){
		return ECDSA.recover(_hashAirdropCallData(data), data.signature);
	}

	function setSigner(address _signer) external onlyOwner {
		cSigner = _signer;
	}

	function getSigner() external view returns(address) {
		return cSigner;
	}

	function toggleClaim() external onlyOwner {
		canClaim = !canClaim;
	}

    function setAirdropRound(uint256 _round) external onlyOwner{
        AirdropRound = _round;
    }

	function claimAirdrop(AirdropCallData calldata data) external{
		require(canClaim, "Cannot claim yet");
		require(data.round == AirdropRound, "Wrong Round");
		require(!ifSecretUsed[data.round][data.secret], "Claimed ALREADY!");
		require(isAirdropCallDataValid(data), "Invaid!");
		require(ifRegistered[data.owner]);
        require(msg.sender == data.owner, "Not your airdrop, sir");
		DegenIDToken.safeTransfer(data.owner, data.amount);
		ifSecretUsed[data.round][data.secret] = true;

		emit Airdropped(data.owner, data.amount);
	}

	function transferAnyERC20Token(address tokenAddress, address receiver, uint256 tokens) public payable onlyOwner returns (bool success) {
        return IERC20(tokenAddress).transfer(receiver, tokens);
    }

	function withdrawFunds() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}
}