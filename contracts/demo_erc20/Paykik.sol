// 0.5.1-c8a2
// Enable optimization
pragma solidity ^0.8.6;

import "../base/TRC20.sol";
import "../base/TRC20Detailed.sol";

/**
 * @title SimpleToken
 * @dev Very simple TRC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `TRC20` functions.
 */
contract PaykikTest is TRC20, TRC20Detailed {
    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor() public TRC20Detailed("PaykikTest", "PaykikTest", 8) {
        _mint(msg.sender, 2000000 * 10 ** 8);
    }
}
