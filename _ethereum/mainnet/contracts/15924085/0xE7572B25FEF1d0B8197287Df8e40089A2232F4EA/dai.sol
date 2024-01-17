// SPDX-License-Identifier: AGPL-3.0-or-later

// Copyright (C) 2017, 2018, 2019 dbrock, rain, mrchico

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.5.15;

import "./lib.sol";

contract Dai is LibNote {
    // --- Auth ---
    mapping (address => uint256) public wards;
    function rely(address guy) external note auth { wards[guy] = 1; }
    function deny(address guy) external note auth { wards[guy] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Hgbp/not-authorized");
        _;
    }

    // --- ERC20 Data ---
    string  public constant name     = "Hgbp Stablecoin";
    string  public constant symbol   = "HGBP";
    string  public constant version  = "1";
    uint8   public constant decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint256)                      public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => uint256)                      public nonces;

    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);

    // --- Math ---
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "Hgbp/add-overflow");
    }
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "Hgbp/sub-underflow");
    }

    // --- EIP712 niceties ---
    uint256 public chainId;
    bytes32 public DOMAIN_SEPARATOR;
    // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");
    bytes32 public constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;

    constructor(uint256 chainId_) public {
        chainId = chainId_;
        wards[msg.sender] = 1;
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            chainId_,
            address(this)
        ));
    }

    // --- Token ---
    function transfer(address dst, uint256 wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }
    function transferFrom(address src, address dst, uint256 wad)
        public returns (bool)
    {
        require(dst != address(0), "Hgbp/zero-address");
        require(balanceOf[src] >= wad, "Hgbp/insufficient-balance");
        if (src != msg.sender && allowance[src][msg.sender] != uint256(-1)) {
            require(allowance[src][msg.sender] >= wad, "Hgbp/insufficient-allowance");
            allowance[src][msg.sender] = sub(allowance[src][msg.sender], wad);
        }
        balanceOf[src] = sub(balanceOf[src], wad);
        balanceOf[dst] = add(balanceOf[dst], wad);
        emit Transfer(src, dst, wad);
        return true;
    }
    function mint(address usr, uint256 wad) external auth {
        require(usr != address(0), "Hgbp/zero-address");
        balanceOf[usr] = add(balanceOf[usr], wad);
        totalSupply    = add(totalSupply, wad);
        emit Transfer(address(0), usr, wad);
    }
    function burn(address usr, uint256 wad) external {
        require(usr != address(0), "Hgbp/zero-address");
        require(balanceOf[usr] >= wad, "Hgbp/insufficient-balance");
        if (usr != msg.sender && allowance[usr][msg.sender] != uint256(-1)) {
            require(allowance[usr][msg.sender] >= wad, "Hgbp/insufficient-allowance");
            allowance[usr][msg.sender] = sub(allowance[usr][msg.sender], wad);
        }
        balanceOf[usr] = sub(balanceOf[usr], wad);
        totalSupply    = sub(totalSupply, wad);
        emit Transfer(usr, address(0), wad);
    }
    function approve(address usr, uint256 wad) public returns (bool) {
        require(usr != address(0), "Hgbp/zero-address");
        allowance[msg.sender][usr] = wad;
        emit Approval(msg.sender, usr, wad);
        return true;
    }
    function increaseApproval(address usr, uint256 wad) external returns (bool) {
        return approve(usr, add(allowance[msg.sender][usr], wad));
    }
    function decreaseApproval(address usr, uint256 wad) external returns (bool) {
        uint256 curr = allowance[msg.sender][usr];
        require(curr >= wad, "Hgbp/decreased-approval-below-zero");
        return approve(usr, sub(curr, wad));
    }

    // --- Alias ---
    function push(address usr, uint256 wad) external {
        transferFrom(msg.sender, usr, wad);
    }
    function pull(address usr, uint256 wad) external {
        transferFrom(usr, msg.sender, wad);
    }
    function move(address src, address dst, uint256 wad) external {
        transferFrom(src, dst, wad);
    }

    // --- Approve by signature ---
    function permit(address holder, address spender, uint256 nonce, uint256 expiry,
                    bool allowed, uint8 v, bytes32 r, bytes32 s) external
    {
        uint256 currChainId;
        assembly {
            currChainId := chainid()
        }
        if (chainId != currChainId) {
            chainId = currChainId;
            DOMAIN_SEPARATOR = keccak256(abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                address(this)
            ));
        }

        bytes32 digest =
            keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH,
                                     holder,
                                     spender,
                                     nonce,
                                     expiry,
                                     allowed))
        ));

        require(holder != address(0), "Hgbp/invalid-address-0");
        require(holder == ecrecover(digest, v, r, s), "Hgbp/invalid-permit");
        require(expiry == 0 || now <= expiry, "Hgbp/permit-expired");
        require(nonce == nonces[holder]++, "Hgbp/invalid-nonce");
        uint256 wad = allowed ? uint256(-1) : 0;
        allowance[holder][spender] = wad;
        emit Approval(holder, spender, wad);
    }
}
