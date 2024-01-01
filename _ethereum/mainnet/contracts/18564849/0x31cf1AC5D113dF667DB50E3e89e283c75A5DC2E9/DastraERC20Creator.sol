// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;
pragma abicoder v2;

import "./DastraERC20Deployer.sol";
import "./DastraERC20BurnableDeployer.sol";
import "./DastraERC20MintableDeployer.sol";
import "./DastraERC20MintableBurnableDeployer.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./ERC2771Context.sol";

contract DastraERC20Creator is ERC2771Context, Ownable {
    using ECDSA for bytes32;

    mapping(address => bool) public signers;
    mapping(uint256 => bool) public nonces;

    address public feeCollector;
    address public trustedForwarder;
    
    event SignerAdded(address _address);
    event SignerRemoved(address _address);
    event TokenMinted(uint256 _nonce, address _address);

    DastraERC20Deployer simpleDeployer;
    DastraERC20MintableDeployer mintableDeployer;
    DastraERC20BurnableDeployer burnableDeployer;
    DastraERC20MintableBurnableDeployer mintableBurnableDeployer;

    constructor(address _feeCollector, address _trustedForwarder) ERC2771Context(_trustedForwarder) {
        simpleDeployer = new DastraERC20Deployer();
        mintableDeployer = new DastraERC20MintableDeployer();
        burnableDeployer = new DastraERC20BurnableDeployer();
        mintableBurnableDeployer = new DastraERC20MintableBurnableDeployer();

        trustedForwarder = _trustedForwarder;
        address sender = _msgSender();
        signers[sender] = true;
        emit SignerAdded(sender);
        feeCollector = _feeCollector;
    }

    function addSigner(address _address) public onlyOwner {
        signers[_address] = true;
        emit SignerAdded(_address);
    }

    function removeSigner(address _address) public onlyOwner {
        signers[_address] = false;
        emit SignerRemoved(_address);
    }

    function mint(
        string memory name,
        string memory symbol,
        bool mintable,
        bool burnable,
        uint8 decimals,
        uint256 initialSupply,
        uint256 cap,
        uint256 nonce,
        uint256 mintPrice,
        bytes memory _signature
    ) public payable returns(address deployed) {
        require(
            nonces[nonce] == false,
            "DastraERC20Creator: Invalid nonce"
        );
        require(msg.value >= mintPrice, "DastraERC20Creator: You should send enough funds for mint");
        require(initialSupply <= cap, "DastraERC20Creator: Cap can't be less than initial supply");

        address sender = _msgSender();
        address signer = keccak256(
            abi.encodePacked(mintable, burnable, decimals, initialSupply, cap, nonce, mintPrice)
        ).toEthSignedMessageHash().recover(_signature);
        
        require(signers[signer], "Invalid signature");

        payable(feeCollector).transfer(mintPrice);

        if (mintable && burnable) {
            deployed = mintableBurnableDeployer.deploy(name, symbol, initialSupply, decimals, cap, trustedForwarder, sender);
        } else if (mintable) {
            deployed = mintableDeployer.deploy(name, symbol, initialSupply, decimals, cap, trustedForwarder, sender);
        } else if (burnable) {
            deployed = burnableDeployer.deploy(name, symbol, initialSupply, decimals, cap, trustedForwarder, sender);
        } else {
            deployed = simpleDeployer.deploy(name, symbol, initialSupply, decimals, cap, trustedForwarder, sender);
        }

        emit TokenMinted(nonce, deployed);

        nonces[nonce] = true;
    }

    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}