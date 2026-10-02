#[test_only]
module hero_game::hero_tests;

use hero_game::hero::{Self, Hero, AdminCap, RewardTicket, Badge};
use sui::test_scenario as ts;

const ADMIN: address = @0xA;
const PLAYER: address = @0xB;

#[test]
fun hero_levels_up_with_ticket() {
    let mut sc = ts::begin(ADMIN);
    hero::init_for_testing(sc.ctx());

    // Player Hero mint karta hai
    sc.next_tx(PLAYER);
    hero::mint_hero(b"Arjun".to_string(), sc.ctx());

    // Admin ticket issue karta hai (250 XP)
    sc.next_tx(ADMIN);
    let cap = sc.take_from_sender<AdminCap>();
    hero::issue_ticket(&cap, 250, PLAYER, sc.ctx());
    sc.return_to_sender(cap);

    // Player ticket redeem karta hai: 250 XP => Level 2, 150 XP bacha
    sc.next_tx(PLAYER);
    let mut h = sc.take_from_sender<Hero>();
    let t = sc.take_from_sender<RewardTicket>();
    hero::redeem_ticket(&mut h, t, sc.ctx());
    assert!(h.level() == 2);
    assert!(h.xp() == 150);
    sc.return_to_sender(h);

    sc.end();
}

#[test]
fun badge_at_level_three() {
    let mut sc = ts::begin(ADMIN);
    hero::init_for_testing(sc.ctx());

    sc.next_tx(PLAYER);
    hero::mint_hero(b"Arjun".to_string(), sc.ctx());

    sc.next_tx(ADMIN);
    let cap = sc.take_from_sender<AdminCap>();
    hero::issue_ticket(&cap, 400, PLAYER, sc.ctx()); // 400 XP => Level 3
    sc.return_to_sender(cap);

    sc.next_tx(PLAYER);
    let mut h = sc.take_from_sender<Hero>();
    let t = sc.take_from_sender<RewardTicket>();
    hero::redeem_ticket(&mut h, t, sc.ctx());
    assert!(h.level() == 3);
    sc.return_to_sender(h);

    // Badge mil gaya?
    sc.next_tx(PLAYER);
    let b = sc.take_from_sender<Badge>();
    sc.return_to_sender(b);

    sc.end();
}
