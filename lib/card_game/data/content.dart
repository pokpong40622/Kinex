import '../models/models.dart';
import '../theme/app_theme.dart';

/// All Thai-language learning content for the balance / fall-prevention deck.
/// Kept as plain data so screens stay dumb and easy to reuse across the
/// three play modes.

const List<Topic> topics = [
  Topic(
    id: TopicId.selfCare,
    title: 'ดูแลตัวเองได้\nอุ่นใจทุกวัน',
    subtitle: 'กินดี นอนพอ ลุกช้าๆ',
    color: AppColors.teal,
    mascot: MascotType.teacup,
  ),
  Topic(
    id: TopicId.home,
    title: 'บ้านสบาย\nเดินสะดวก',
    subtitle: 'จัดบ้านให้ปลอดภัย',
    color: AppColors.skyBlue,
    mascot: MascotType.house,
  ),
  Topic(
    id: TopicId.movement,
    title: 'ขยับนิดหน่อย\nแข็งแรงสดใส',
    subtitle: 'ขยับกาย ทรงตัวดี',
    color: AppColors.sunYellow,
    mascot: MascotType.sun,
  ),
  Topic(
    id: TopicId.medicine,
    title: 'กินยา ดูแลสายตา\nให้สบายตัว',
    subtitle: 'ยาถูกต้อง ตาแจ่มใส',
    color: AppColors.orange,
    mascot: MascotType.glassesPill,
  ),
  Topic(
    id: TopicId.companionship,
    title: 'มีคนอยู่ข้างๆ\nเสมอ',
    subtitle: 'ไม่ต้องลำบากคนเดียว',
    color: AppColors.coralPink,
    mascot: MascotType.heartHands,
  ),
];

Topic topicById(TopicId id) => topics.firstWhere((t) => t.id == id);

// ---------------------------------------------------------------------------
// Multiple choice (ก ข ค ง)
// ---------------------------------------------------------------------------

final Map<TopicId, List<McQuestion>> mcQuestions = {
  TopicId.selfCare: const [
    McQuestion(
      topic: TopicId.selfCare,
      illustration: PictogramType.bed,
      question: 'ตอนเช้าจะลุกจากเตียง ควรทำอย่างไรดีที่สุด?',
      options: [
        'ลุกขึ้นยืนทันที',
        'นั่งพักที่ขอบเตียงสักครู่ก่อนค่อยยืน',
        'กระโดดลงจากเตียง',
        'รีบลุกให้เร็วที่สุด',
      ],
      correctIndex: 1,
    ),
    McQuestion(
      topic: TopicId.selfCare,
      illustration: PictogramType.shoes,
      question: 'รองเท้าแบบไหนช่วยให้เดินมั่นคง ไม่ลื่นล้ม?',
      options: [
        'รองเท้าส้นสูง',
        'รองเท้าแตะพื้นลื่น',
        'รองเท้าพอดีเท้า พื้นกันลื่น',
        'เดินเท้าเปล่าตลอดเวลา',
      ],
      correctIndex: 2,
    ),
    McQuestion(
      topic: TopicId.selfCare,
      illustration: PictogramType.waterGlass,
      question: 'การดื่มน้ำให้เพียงพอในแต่ละวันช่วยเรื่องใด?',
      options: [
        'ช่วยลดอาการเวียนหัวและอ่อนแรง',
        'ทำให้ปวดฟัน',
        'ไม่มีผลอะไรเลย',
        'ทำให้ง่วงนอนตลอดเวลา',
      ],
      correctIndex: 0,
    ),
    McQuestion(
      topic: TopicId.selfCare,
      illustration: PictogramType.foodPlate,
      question: 'อาหารกลุ่มใดช่วยให้กระดูกและกล้ามเนื้อแข็งแรง?',
      options: [
        'ขนมหวานจัด',
        'นม ไข่ ปลา และผักใบเขียว',
        'น้ำอัดลม',
        'ของทอดมันๆ อย่างเดียว',
      ],
      correctIndex: 1,
    ),
  ],
  TopicId.home: const [
    McQuestion(
      topic: TopicId.home,
      illustration: PictogramType.bathroomMat,
      question: 'พื้นห้องน้ำที่เปียก ควรทำอย่างไร?',
      options: [
        'เดินข้ามไปโดยไม่สนใจ',
        'ใช้แผ่นกันลื่นและเช็ดพื้นให้แห้งเสมอ',
        'ปล่อยน้ำขังไว้เฉยๆ',
        'วิ่งข้ามให้เร็วที่สุด',
      ],
      correctIndex: 1,
    ),
    McQuestion(
      topic: TopicId.home,
      illustration: PictogramType.stairsHandrail,
      question: 'บันไดในบ้านควรมีอะไรเพื่อความปลอดภัย?',
      options: [
        'ไม่ต้องมีแสงไฟก็ได้',
        'ราวจับและไฟส่องสว่างเพียงพอ',
        'วางของซ้อนไว้บนขั้นบันได',
        'ปูพรมหนาที่ไม่ยึดติดพื้น',
      ],
      correctIndex: 1,
    ),
    McQuestion(
      topic: TopicId.home,
      illustration: PictogramType.rugCord,
      question: 'พรมหรือสายไฟที่วางเกะกะพื้น ควรทำอย่างไร?',
      options: [
        'ปล่อยไว้เหมือนเดิม',
        'วางเพิ่มให้มากขึ้น',
        'เก็บให้เรียบร้อย ไม่ให้ขวางทางเดิน',
        'ซ่อนไว้ใต้เตียง',
      ],
      correctIndex: 2,
    ),
    McQuestion(
      topic: TopicId.home,
      illustration: PictogramType.nightLight,
      question: 'ตื่นมาเข้าห้องน้ำตอนกลางคืน ควรมีอะไรช่วย?',
      options: [
        'เดินในความมืดสนิท',
        'ปิดไฟทุกดวงในบ้าน',
        'งดเข้าห้องน้ำตอนกลางคืน',
        'ไฟหรือโคมไฟดวงเล็กส่องทาง',
      ],
      correctIndex: 3,
    ),
  ],
  TopicId.movement: const [
    McQuestion(
      topic: TopicId.movement,
      illustration: PictogramType.taichi,
      question: 'การออกกำลังกายแบบใดช่วยเรื่องการทรงตัวได้ดี?',
      options: [
        'นอนเฉยๆ ทั้งวัน',
        'รำมวยจีนหรือเดินเบาๆ เป็นประจำ',
        'วิ่งเร็วสุดแรงทันที',
        'งดการเคลื่อนไหวทุกชนิด',
      ],
      correctIndex: 1,
    ),
    McQuestion(
      topic: TopicId.movement,
      illustration: PictogramType.stretching,
      question: 'ก่อนออกกำลังกาย ควรทำอะไรก่อน?',
      options: [
        'ยืดเส้นยืดสายอุ่นร่างกายเบาๆ',
        'กระโดดแรงๆ ทันที',
        'กลั้นหายใจไว้',
        'ไม่ต้องเตรียมตัวเลย',
      ],
      correctIndex: 0,
    ),
    McQuestion(
      topic: TopicId.movement,
      illustration: PictogramType.balanceChair,
      question: 'การฝึกยืนขาเดียวโดยจับพนักเก้าอี้ ช่วยเรื่องใด?',
      options: [
        'เสริมสร้างการทรงตัว',
        'ทำให้เวียนหัว',
        'ไม่มีประโยชน์',
        'ทำให้ปวดหลังเสมอ',
      ],
      correctIndex: 0,
    ),
    McQuestion(
      topic: TopicId.movement,
      illustration: PictogramType.calendarRoutine,
      question: 'ควรออกกำลังกายบ่อยแค่ไหนจึงจะดีต่อร่างกาย?',
      options: [
        'ปีละครั้งก็พอ',
        'หักโหมให้ครบวันเดียว',
        'เป็นประจำสม่ำเสมอ ทีละนิดแต่ต่อเนื่อง',
        'ไม่จำเป็นต้องขยับเลย',
      ],
      correctIndex: 2,
    ),
  ],
  TopicId.medicine: const [
    McQuestion(
      topic: TopicId.medicine,
      illustration: PictogramType.pillDoctor,
      question: 'ถ้ากินยาแล้วรู้สึกเวียนหัวหรือง่วงผิดปกติ ควรทำอย่างไร?',
      options: [
        'ทนไว้ไม่ต้องบอกใคร',
        'แจ้งแพทย์หรือเภสัชกรทันที',
        'เพิ่มยาเองให้มากขึ้น',
        'หยุดยาทุกชนิดเองทันที',
      ],
      correctIndex: 1,
    ),
    McQuestion(
      topic: TopicId.medicine,
      illustration: PictogramType.glasses,
      question: 'ควรตรวจวัดสายตาบ่อยแค่ไหน?',
      options: [
        'ไม่ต้องตรวจเลย',
        'ตรวจเมื่อมองไม่เห็นแล้วเท่านั้น',
        'ตรวจเป็นประจำตามที่แพทย์แนะนำ',
        'ยืมแว่นคนอื่นมาใส่แทน',
      ],
      correctIndex: 2,
    ),
    McQuestion(
      topic: TopicId.medicine,
      illustration: PictogramType.glassesClean,
      question: 'แว่นตาที่ใส่อยู่ควรเป็นแบบใด?',
      options: [
        'แว่นบานไหนก็ได้',
        'ค่าสายตาตรงกับตัวเอง เลนส์สะอาดไม่มีรอยขีดข่วน',
        'แว่นที่มัวๆ เพราะเลนส์เก่า',
        'ไม่ใส่แว่นแม้มองไม่ชัด',
      ],
      correctIndex: 1,
    ),
    McQuestion(
      topic: TopicId.medicine,
      illustration: PictogramType.pillSchedule,
      question: 'การกินยาให้ถูกต้องปลอดภัยควรทำอย่างไร?',
      options: [
        'กินตามใจตัวเองได้ทุกเวลา',
        'แบ่งยาให้คนอื่นกินด้วย',
        'ลืมกินก็ไม่เป็นไร',
        'กินตามคำแนะนำแพทย์ ตรงเวลา ตรงขนาด',
      ],
      correctIndex: 3,
    ),
  ],
  TopicId.companionship: const [
    McQuestion(
      topic: TopicId.companionship,
      illustration: PictogramType.cane,
      question: 'ถ้ารู้สึกไม่มั่นใจเวลาเดิน ควรทำอย่างไร?',
      options: [
        'ฝืนเดินคนเดียวไม่บอกใคร',
        'ขอความช่วยเหลือหรือใช้ไม้เท้าช่วยพยุง',
        'วิ่งให้เร็วขึ้นเพื่อผ่านไปให้ไว',
        'เลี่ยงการเดินไปตลอด',
      ],
      correctIndex: 1,
    ),
    McQuestion(
      topic: TopicId.companionship,
      illustration: PictogramType.familyTalk,
      question: 'หากเคยหกล้มมาก่อน ควรทำอย่างไร?',
      options: [
        'เก็บไว้คนเดียวไม่ต้องบอกใคร',
        'ไม่ต้องสนใจ ปล่อยผ่านไป',
        'โทษตัวเองว่าไม่ระวัง',
        'เล่าให้ลูกหลานหรือแพทย์ฟังเพื่อดูแลต่อ',
      ],
      correctIndex: 3,
    ),
    McQuestion(
      topic: TopicId.companionship,
      illustration: PictogramType.phoneEmergency,
      question: 'อุปกรณ์ใดช่วยขอความช่วยเหลือได้รวดเร็วเมื่อจำเป็น?',
      options: [
        'ปุ่มกดฉุกเฉินหรือโทรศัพท์ที่พกติดตัว',
        'ไม่ต้องมีอุปกรณ์ใดเลย',
        'เก็บโทรศัพท์ไว้ห้องอื่น',
        'ปิดเสียงโทรศัพท์เสมอ',
      ],
      correctIndex: 0,
    ),
    McQuestion(
      topic: TopicId.companionship,
      illustration: PictogramType.friendsCommunity,
      question: 'การเข้าร่วมกิจกรรมกับเพื่อนหรือครอบครัวช่วยเรื่องใด?',
      options: [
        'ทำให้เหนื่อยโดยเปล่าประโยชน์',
        'ทำให้อุ่นใจ ร่างกายและใจแจ่มใส',
        'ไม่มีผลดีใดๆ',
        'ควรอยู่คนเดียวตลอดเวลาดีกว่า',
      ],
      correctIndex: 1,
    ),
  ],
};

// ---------------------------------------------------------------------------
// True / False (ถูก / ผิด)
// ---------------------------------------------------------------------------

final Map<TopicId, List<TfQuestion>> tfQuestions = {
  TopicId.selfCare: const [
    TfQuestion(
      topic: TopicId.selfCare,
      illustration: PictogramType.bed,
      statement: 'การนอนหลับให้เพียงพอช่วยให้ร่างกายทรงตัวดีขึ้น',
      correctAnswer: true,
    ),
    TfQuestion(
      topic: TopicId.selfCare,
      illustration: PictogramType.shoes,
      statement: 'ควรลุกจากที่นั่งหรือเตียงเร็วๆ ทันทีเพื่อประหยัดเวลา',
      correctAnswer: false,
    ),
    TfQuestion(
      topic: TopicId.selfCare,
      illustration: PictogramType.foodPlate,
      statement: 'การตรวจสุขภาพเป็นประจำช่วยให้ดูแลตัวเองได้ทันท่วงที',
      correctAnswer: true,
    ),
    TfQuestion(
      topic: TopicId.selfCare,
      illustration: PictogramType.waterGlass,
      statement: 'ใส่รองเท้าหลวมๆ ลื่นๆ ก็ไม่เป็นไร',
      correctAnswer: false,
    ),
  ],
  TopicId.home: const [
    TfQuestion(
      topic: TopicId.home,
      illustration: PictogramType.stairsHandrail,
      statement: 'ควรติดราวจับในห้องน้ำและข้างบันได',
      correctAnswer: true,
    ),
    TfQuestion(
      topic: TopicId.home,
      illustration: PictogramType.rugCord,
      statement: 'วางของเกะกะทางเดินไม่เป็นไร เดี๋ยวก็ชิน',
      correctAnswer: false,
    ),
    TfQuestion(
      topic: TopicId.home,
      illustration: PictogramType.nightLight,
      statement: 'แสงสว่างเพียงพอในบ้านช่วยลดความเสี่ยงหกล้ม',
      correctAnswer: true,
    ),
    TfQuestion(
      topic: TopicId.home,
      illustration: PictogramType.bathroomMat,
      statement: 'พื้นห้องน้ำลื่นๆ ไม่จำเป็นต้องมีแผ่นกันลื่น',
      correctAnswer: false,
    ),
  ],
  TopicId.movement: const [
    TfQuestion(
      topic: TopicId.movement,
      illustration: PictogramType.taichi,
      statement: 'การเดินเบาๆ ทุกวันช่วยให้กล้ามเนื้อขาแข็งแรง',
      correctAnswer: true,
    ),
    TfQuestion(
      topic: TopicId.movement,
      illustration: PictogramType.stretching,
      statement: 'ควรออกกำลังกายหักโหมทันทีโดยไม่วอร์มอัพ',
      correctAnswer: false,
    ),
    TfQuestion(
      topic: TopicId.movement,
      illustration: PictogramType.balanceChair,
      statement: 'การฝึกทรงตัวควรมีที่จับหรือคนช่วยดูแลอยู่ใกล้ๆ',
      correctAnswer: true,
    ),
    TfQuestion(
      topic: TopicId.movement,
      illustration: PictogramType.calendarRoutine,
      statement: 'ไม่ควรขยับตัวเลยเพราะกลัวหกล้ม',
      correctAnswer: false,
    ),
  ],
  TopicId.medicine: const [
    TfQuestion(
      topic: TopicId.medicine,
      illustration: PictogramType.pillDoctor,
      statement: 'ยาบางชนิดอาจทำให้เวียนหัวหรือง่วงซึม ควรระวังเวลาลุกเดิน',
      correctAnswer: true,
    ),
    TfQuestion(
      topic: TopicId.medicine,
      illustration: PictogramType.pillSchedule,
      statement: 'ควรปรับขนาดยาเองได้โดยไม่ต้องถามแพทย์',
      correctAnswer: false,
    ),
    TfQuestion(
      topic: TopicId.medicine,
      illustration: PictogramType.glassesClean,
      statement: 'แว่นตาที่มัวหรือเลนส์เก่าอาจทำให้มองทางไม่ชัดและเสี่ยงหกล้ม',
      correctAnswer: true,
    ),
    TfQuestion(
      topic: TopicId.medicine,
      illustration: PictogramType.glasses,
      statement: 'ไม่จำเป็นต้องตรวจสายตาถ้ายังพอมองเห็น',
      correctAnswer: false,
    ),
  ],
  TopicId.companionship: const [
    TfQuestion(
      topic: TopicId.companionship,
      illustration: PictogramType.familyTalk,
      statement:
          'ควรบอกลูกหลานหรือคนใกล้ชิดเมื่อรู้สึกไม่สบายหรือเดินไม่มั่นคง',
      correctAnswer: true,
    ),
    TfQuestion(
      topic: TopicId.companionship,
      illustration: PictogramType.cane,
      statement: 'การขอความช่วยเหลือเมื่อจำเป็นเป็นเรื่องน่าอาย',
      correctAnswer: false,
    ),
    TfQuestion(
      topic: TopicId.companionship,
      illustration: PictogramType.phoneEmergency,
      statement: 'การพกโทรศัพท์หรือปุ่มฉุกเฉินติดตัวช่วยให้อุ่นใจมากขึ้น',
      correctAnswer: true,
    ),
    TfQuestion(
      topic: TopicId.companionship,
      illustration: PictogramType.friendsCommunity,
      statement: 'ควรปิดกั้นตัวเอง ไม่พบปะใครเลยจะปลอดภัยที่สุด',
      correctAnswer: false,
    ),
  ],
};

// ---------------------------------------------------------------------------
// Matching (จับคู่: สถานการณ์ -> วิธีดูแล)
// ---------------------------------------------------------------------------

final Map<TopicId, List<MatchPair>> matchPairs = {
  TopicId.selfCare: const [
    MatchPair(
      topic: TopicId.selfCare,
      situationIllustration: PictogramType.bed,
      situation: 'รู้สึกวิงเวียนเวลาลุกยืนเร็วๆ',
      tipIllustration: PictogramType.bed,
      tip: 'ลุกช้าๆ นั่งพักก่อนยืน',
    ),
    MatchPair(
      topic: TopicId.selfCare,
      situationIllustration: PictogramType.waterGlass,
      situation: 'รู้สึกกระหายน้ำบ่อย ปากแห้ง',
      tipIllustration: PictogramType.waterGlass,
      tip: 'จิบน้ำบ่อยๆ ระหว่างวัน',
    ),
    MatchPair(
      topic: TopicId.selfCare,
      situationIllustration: PictogramType.shoes,
      situation: 'รองเท้าคู่เก่าพื้นลื่นสึกแล้ว',
      tipIllustration: PictogramType.shoes,
      tip: 'เปลี่ยนรองเท้าใหม่ พื้นกันลื่น',
    ),
    MatchPair(
      topic: TopicId.selfCare,
      situationIllustration: PictogramType.foodPlate,
      situation: 'นอนดึก ตื่นเช้าอ่อนเพลีย',
      tipIllustration: PictogramType.foodPlate,
      tip: 'เข้านอนแต่หัวค่ำ นอนให้ครบ 7-8 ชม.',
    ),
  ],
  TopicId.home: const [
    MatchPair(
      topic: TopicId.home,
      situationIllustration: PictogramType.bathroomMat,
      situation: 'พื้นห้องน้ำลื่น เดินแล้วหวาดเสียว',
      tipIllustration: PictogramType.bathroomMat,
      tip: 'ปูแผ่นกันลื่น เช็ดพื้นให้แห้ง',
    ),
    MatchPair(
      topic: TopicId.home,
      situationIllustration: PictogramType.stairsHandrail,
      situation: 'เดินขึ้นลงบันไดแล้วไม่มั่นใจ',
      tipIllustration: PictogramType.stairsHandrail,
      tip: 'ติดราวจับ เดินช้าๆ ทีละขั้น',
    ),
    MatchPair(
      topic: TopicId.home,
      situationIllustration: PictogramType.rugCord,
      situation: 'สายไฟพาดผ่านทางเดินในบ้าน',
      tipIllustration: PictogramType.rugCord,
      tip: 'เก็บสายไฟให้เรียบร้อย พ้นทางเดิน',
    ),
    MatchPair(
      topic: TopicId.home,
      situationIllustration: PictogramType.nightLight,
      situation: 'ตื่นกลางดึก มืดมองไม่เห็นทาง',
      tipIllustration: PictogramType.nightLight,
      tip: 'เปิดไฟดวงเล็กหรือไฟทางเดิน',
    ),
  ],
  TopicId.movement: const [
    MatchPair(
      topic: TopicId.movement,
      situationIllustration: PictogramType.balanceChair,
      situation: 'รู้สึกขาไม่ค่อยมีแรง เดินแล้วโซเซ',
      tipIllustration: PictogramType.balanceChair,
      tip: 'ฝึกยืนขาเดียวจับพนักเก้าอี้ทีละน้อย',
    ),
    MatchPair(
      topic: TopicId.movement,
      situationIllustration: PictogramType.taichi,
      situation: 'อยากออกกำลังกายแต่กลัวหักโหม',
      tipIllustration: PictogramType.taichi,
      tip: 'เริ่มจากเดินเบาๆ หรือรำไทเก็ก',
    ),
    MatchPair(
      topic: TopicId.movement,
      situationIllustration: PictogramType.stretching,
      situation: 'ตัวเริ่มแข็ง ขยับลำบากตอนเช้า',
      tipIllustration: PictogramType.stretching,
      tip: 'ยืดเส้นยืดสายเบาๆ ก่อนลุกจากเตียง',
    ),
    MatchPair(
      topic: TopicId.movement,
      situationIllustration: PictogramType.calendarRoutine,
      situation: 'นั่งอยู่กับที่ทั้งวันไม่ค่อยได้ขยับ',
      tipIllustration: PictogramType.calendarRoutine,
      tip: 'ลุกยืดตัว เดินเบาๆ ทุกๆ ชั่วโมง',
    ),
  ],
  TopicId.medicine: const [
    MatchPair(
      topic: TopicId.medicine,
      situationIllustration: PictogramType.pillDoctor,
      situation: 'กินยาแล้วรู้สึกง่วงเซื่องซึมผิดปกติ',
      tipIllustration: PictogramType.pillDoctor,
      tip: 'แจ้งแพทย์หรือเภสัชกรให้ทราบ',
    ),
    MatchPair(
      topic: TopicId.medicine,
      situationIllustration: PictogramType.glasses,
      situation: 'มองภาพเบลอ อ่านหนังสือไม่ชัด',
      tipIllustration: PictogramType.glasses,
      tip: 'ไปตรวจวัดสายตาและเปลี่ยนแว่นใหม่',
    ),
    MatchPair(
      topic: TopicId.medicine,
      situationIllustration: PictogramType.pillSchedule,
      situation: 'ลืมว่ากินยามื้อนี้ไปหรือยัง',
      tipIllustration: PictogramType.pillSchedule,
      tip: 'จัดกล่องยาแยกตามมื้อ ตามวัน',
    ),
    MatchPair(
      topic: TopicId.medicine,
      situationIllustration: PictogramType.glassesClean,
      situation: 'แว่นตาเก่ามีรอยขีดข่วนมัวๆ',
      tipIllustration: PictogramType.glassesClean,
      tip: 'ทำความสะอาดหรือเปลี่ยนแว่นใหม่',
    ),
  ],
  TopicId.companionship: const [
    MatchPair(
      topic: TopicId.companionship,
      situationIllustration: PictogramType.cane,
      situation: 'เดินคนเดียวแล้วรู้สึกไม่มั่นคง',
      tipIllustration: PictogramType.cane,
      tip: 'ใช้ไม้เท้าช่วยพยุง หรือชวนคนเดินด้วย',
    ),
    MatchPair(
      topic: TopicId.companionship,
      situationIllustration: PictogramType.familyTalk,
      situation: 'เคยหกล้มแต่ไม่กล้าบอกใคร',
      tipIllustration: PictogramType.familyTalk,
      tip: 'เล่าให้ครอบครัวหรือแพทย์ฟัง',
    ),
    MatchPair(
      topic: TopicId.companionship,
      situationIllustration: PictogramType.phoneEmergency,
      situation: 'อยู่บ้านคนเดียวตอนกลางวัน',
      tipIllustration: PictogramType.phoneEmergency,
      tip: 'พกโทรศัพท์หรือปุ่มฉุกเฉินติดตัว',
    ),
    MatchPair(
      topic: TopicId.companionship,
      situationIllustration: PictogramType.friendsCommunity,
      situation: 'รู้สึกเหงา ไม่ค่อยได้พบปะใคร',
      tipIllustration: PictogramType.friendsCommunity,
      tip: 'เข้าร่วมกิจกรรมกับเพื่อนหรือชมรมผู้สูงวัย',
    ),
  ],
};
