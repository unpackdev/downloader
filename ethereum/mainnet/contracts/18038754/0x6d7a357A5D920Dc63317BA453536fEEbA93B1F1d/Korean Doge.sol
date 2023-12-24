// https://koreandoge.com/
// https://t.me/JindotgaeOfficialPortal
// https://twitter.com/JindotgaeERC20

/* 
진도개
첫 번째 한국 도지코인
Korean First Inu Coin

진도견은 한국의 진도 섬에 원산하는 토종 개입니다.
이견은 또한 '진도견'이라고 알려져 있으며 이전에는 '친도견'으로 알려져 있었습니다.
모든 메타 미미 코인에 지치셨나요? 이것은 시장을 접수할 이누 코인입니다.

총 공급량: 4206900000
세금: 0%
유동성 잠금 (Liquidity Lock)
계약 포기 (Contract renounced)
공정 런칭 (Fair Launch)
팀 토큰 없음 (No team token)
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract KoreanDoge is ERC20 { 
    constructor() ERC20("Korean Doge", unicode"진도개") { 
        _mint(msg.sender, 4_206_900_000 * 10**18);
    }
}