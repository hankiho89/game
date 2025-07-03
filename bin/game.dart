import 'dart:io';
import 'dart:math';

abstract class Entity {
  String name;
  int health;
  int attackPower;
  int defensePower;

  Entity(this.name, this.health, this.attackPower, this.defensePower);

  void showStatus() {
    print('$name 상태 → 체력: $health, 공격력: $attackPower, 방어력: $defensePower');
  }
}

class Character extends Entity {
  bool itemUsed = false;
  bool isUsingItem = false;
  int initialHealth;
  bool hasPotion = true;

  Character(String name, int health, int attackPower, int defensePower)
      : initialHealth = health,
        super(name, health, attackPower, defensePower);

  void applyBonusHealth() {
    if (Random().nextInt(100) < 30) {
      health += 10;
      print('보너스 체력을 얻었습니다! 현재 체력: $health');
    }
  }

  void attackMonster(Monster monster) {
    int effectiveAttack = isUsingItem ? attackPower * 2 : attackPower;
    int damage = max(0, effectiveAttack - monster.defensePower);
    print('$name이(가) ${monster.name}을(를) 공격합니다! 데미지: $damage');
    monster.health -= damage;
    if (monster.health < 0) monster.health = 0;
    isUsingItem = false;
  }

  void defend() {
    print('$name이(가) 방어합니다. 체력이 방어력만큼 회복됩니다.');
    health += defensePower;
  }

  void useItem() {
    if (itemUsed) {
      print('아이템은 이미 사용되었습니다!');
      return;
    }
    itemUsed = true;
    isUsingItem = true;
    print('아이템을 사용했습니다! 이번 턴 공격력 2배!');
  }

  void usePotion() {
    if (!hasPotion) {
      print('물약이 없습니다.');
      return;
    }
    // 물약 사용시 체력 30 회복
    hasPotion = false;
    health += 30;
    print('물약을 사용했습니다! 체력이 30 회복되었습니다. 현재 체력: $health');
  }
// 보스를 잡을 때 물약을 재충전합니다.
  void rechargePotion() {
    hasPotion = true;
    print('💧 물약이 재충전되었습니다!');
  }
// 레벨업 할 때마다 공격력과 체력을 증가시키고, 체력을 완전히 회복합니다. 
  void levelUp() {
    attackPower += 5;
    initialHealth += 20;
    health = initialHealth;
    print('\n🎉 레벨업! 공격력 +5, 체력 완전 회복 → 현재 체력: $health');
    showStatus();
  }
}

class Monster extends Entity {
  int maxAttackPower;
  int turnCounter = 0;

  Monster(String name, int health, this.maxAttackPower)
      : super(name, health, max(maxAttackPower, 1), 0);

  void attackCharacter(Character character) {
    attackPower = max(character.defensePower,
        Random().nextInt(maxAttackPower) + 1);
    int damage = max(0, attackPower - character.defensePower);
    print('$name이(가) ${character.name}을(를) 공격합니다! 데미지: $damage');
    character.health -= damage;
    if (character.health < 0) character.health = 0;
  }

  void increaseDefenseIfNeeded() {
    turnCounter++;
    if (turnCounter == 3) {
      defensePower += 2;
      print('$name의 방어력이 증가했습니다! 현재 방어력: $defensePower');
      turnCounter = 0;
    }
  }
}

class Game {
  late Character character;
  List<Monster> baseMonsters = [];
  List<Monster> currentMonsters = [];
  List<Monster> bosses = [];
  int currentBossIndex = 0;
  int level = 1;

  void startGame() {
    _loadCharacterStats();
    _loadMonsterStats();
    _loadBossStats();
    character.applyBonusHealth();

    while (character.health > 0) {
      print('\n🔥 몬스터와 전투 시작!');
      _fightMonsters(3);

      if (character.health <= 0) break;

      character.levelUp();
      if (currentBossIndex >= bosses.length) {
        print('모든 보스를 처치했습니다! 최종 승리 🎉');
        _saveResult('최종 승리');
        break;
      }

      print('\n🌟 보스 등장: ${bosses[currentBossIndex].name}');
      _fightOne(bosses[currentBossIndex]);

      if (character.health <= 0) break;

      if (currentBossIndex == bosses.length - 1) {
    print('모든 보스를 처치했습니다! 최종 승리 🎉');
    _saveResult('최종 승리');
    return;
  }

  print('${bosses[currentBossIndex].name} 처치 완료!');
  character.rechargePotion(); // 💧 물약 재충전
  currentBossIndex++;
  level++;

  _powerUpMonsters();

    }

    if (character.health <= 0) {
      print('\n패배했습니다...');
      _saveResult('패배');
    }
  }

  void _fightMonsters(int count) {
    currentMonsters = List.generate(count, (_) => _getRandomMonster());
    for (var m in currentMonsters) {
      print('\n몬스터 등장: ${m.name}');
      _fightOne(m);
      if (character.health <= 0) break;
    }
  }

  void _fightOne(Monster m) {
    while (character.health > 0 && m.health > 0) {
      print('\n==============================');
      print('🧙${character.name}의 턴');
      character.showStatus();
      m.showStatus();

      stdout.write('행동 선택 (1: 공격, 2: 방어, 3: 아이템, 4: 물약): ');
      String? choice = stdin.readLineSync();

      if (choice == '1') character.attackMonster(m); 
      else if (choice == '2') character.defend();
      else if (choice == '3') character.useItem();
      else if (choice == '4') character.usePotion();
      else {
        print('잘못된 입력입니다.');
        continue;
      }

      if (m.health > 0) {
        print('\n------------------------------');
        print('👹 ${m.name}의 턴');
        m.increaseDefenseIfNeeded();
        m.attackCharacter(character);
      }
    }

    if (m.health <= 0) {
      print('\n ${m.name}을(를) 물리쳤습니다!');
      print('==============================\n');
    }
  }

  Monster _getRandomMonster() {
    final template = baseMonsters[Random().nextInt(baseMonsters.length)];
    int boostedHealth = (template.health * pow(1.3, level - 1)).toInt();
    int boostedAttack = (template.maxAttackPower * pow(1.3, level - 1)).toInt();
    return Monster(template.name, boostedHealth, boostedAttack);
  }

  void _powerUpMonsters() {
    print('\n💥 몬스터들이 더 강해졌습니다!');
  }

  void _loadCharacterStats() {
    final stats = File('characters.txt').readAsStringSync().trim().split(',');
    stdout.write('캐릭터 이름 입력: ');
    String name = stdin.readLineSync()!;
    while (!RegExp(r'^[a-zA-Z가-힣]+$').hasMatch(name)) {
      stdout.write('다시 입력 (한글/영문만 허용): ');
      name = stdin.readLineSync()!;
    }
    character = Character(name, int.parse(stats[0]), int.parse(stats[1]), int.parse(stats[2]));
  }

  void _loadMonsterStats() {
    baseMonsters = File('monsters.txt')
        .readAsLinesSync()
        .map((line) {
          final parts = line.trim().split(',');
          return Monster(parts[0], int.parse(parts[1]), int.parse(parts[2]));
        })
        .toList();
  }
// 보스 몬스터 스탯을 로드합니다.
  void _loadBossStats() {
    bosses = [
      Monster('보스1단계', 70, 13),
      Monster('보스2단계', 90, 18),
      Monster('보스3단계', 120, 23),
    ];
  }

  void _saveResult(String result) {
    stdout.write('결과 저장하시겠습니까? (y/n): ');
    if ((stdin.readLineSync() ?? '').toLowerCase() == 'y') {
      File('result.txt').writeAsStringSync(
          '캐릭터: ${character.name}, 체력: ${character.health}, 결과: $result');
      print('결과 저장됨.');
    }
  }
}

void main() {
  Game().startGame();
}
