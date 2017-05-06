＃iOS-常见题目总结
1，下面的代码输出什么？

   @implementation Son : Father
     - (id)init
     {
         self = [super init];
         if (self) {
             NSLog(@"%@", NSStringFromClass([self class]));
             NSLog(@"%@", NSStringFromClass([super class]));
         }
         return self;
     }
   @end

     都输出 Son

self 和 super 的区别：
	
	self 是类的隐藏参数，指向当前调用方法的这个类的实例；

	super 是一个 Magic Keyword， 它本质是一个编译器标示符，和 self 是指向的同一个消息接受者！

	他们两个的不同点在于：super 会告诉编译器，调用 class 这个方法时，要去父类的方法，而不是本类里的。

上面的例子不管调用[self class]还是[super class]，接受消息的对象都是当前 Son ＊xxx 这个对象。

	调用 [self class] 会转化成 objc_msgSend函数：  id objc_msgSend(id self, SEL op, ...);第一个参数把self 传进去

	而调用 [super class] 时会转化成 objc_msgSendSuper函数： id objc_msgSendSuper(struct objc_super *super, SEL op, ...)

		第一个参数是 objc_super 这样一个结构体：

			struct objc_super {
			      __unsafe_unretained id receiver;
			      __unsafe_unretained Class super_class;
			};

			这个结构体有两个成员，第一个是 receiver ，类似于objc_msgSend函数第一个参数self ；第二个参数是记录当前类的父类是什么；

	执行[super class] 时会分两步进行：第一步先构造 objc_super 结构体；结构体第一个成员就是 self ； 第二个成员是 (id)class_getSuperclass(objc_getClass(“Son”)) , 实际该函数输出结果为 Father

				第二步回去Father这个类里面去找 - (Class)class 这个函数，没有找到然后去NSObject类里面去找，找到了。最后内部是使用 objc_msgSend(objc_super->receiver, @selector(class))去调用。

				此时已经和[self class]调用相同了，故上述输出结果仍然返回 Son；

2，runtime如何通过selector找到对应的IMP地址？（分别考虑类方法和实例方法）
	
	每一个类对象中都一个方法列表,方法列表中记录着方法的名称,方法实现,以及参数类型,其实selector本质就是方法名称,通过这个方法名称就可以在方法列表中找到对应的方法实现

3，objc中的类方法和实例方法有什么本质区别和联系？

 	类方法：

		类方法是属于类对象的
		
		类方法只能通过类对象调用
		
		类方法中的self是类对象.
		
		类方法可以调用其他的类方法
		
		类方法中不能访问成员变量
		
		类方法中不能直接调用对象方法
	
	实例方法：

		实例方法是属于实例对象的
	
		实例方法只能通过实例对象调用
	
		实例方法中的self是实例对象.
	
		实例方法中可以访问成员变量
	
		实例方法中直接调用实例方法
	
		实例方法中也可以调用类方法 通过类名

4，_objc_msgForward函数是做什么的，直接调用它将会发生什么？
	
	_objc_msgForward是 IMP 类型，用于消息转发的：当向一个对象发送一条消息，但它并没有实现的时候，_objc_msgForward会尝试做消息转发。

	消息调用流程：

		1.调用resolveInstanceMethod:方法 (或 resolveClassMethod:)。允许用户在此时为该 Class 动态添加实现。如果有实现了，则调用并返回YES，那么重新开始objc_msgSend流程。这一次对象会响应这个选择器，一般是因为它已经调用过class_addMethod。如果仍没实现，继续下面的动作。

		2.调用forwardingTargetForSelector:方法，尝试找到一个能响应该消息的对象。如果获取到，则直接把消息转发给它，返回非 nil 对象。否则返回 nil ，继续下面的动作。注意，这里不要返回 self ，否则会形成死循环。

		3.调用methodSignatureForSelector:方法，尝试获得一个方法签名。如果获取不到，则直接调用doesNotRecognizeSelector抛出异常。如果能获取，则返回非nil：创建一个 NSlnvocation 并传给forwardInvocation:。

		4.调用forwardInvocation:方法，将第3步获取到的方法签名包装成 Invocation 传入，如何处理就在这里面了，并返回非ni。

		5.调用doesNotRecognizeSelector: ，默认的实现是抛出异常。如果第3步没能获得一个方法签名，执行该步骤。

	_objc_msgForward在进行消息转发的过程中会涉及以下这几个方法：

		resolveInstanceMethod:方法 (或 resolveClassMethod:)。

		forwardingTargetForSelector:方法

		methodSignatureForSelector:方法

		forwardInvocation:方法

		doesNotRecognizeSelector: 方法

	直接调用_objc_msgForward是非常危险的事，如果用不好会直接导致程序Crash，但是如果用得好，能做很多非常酷的事。

5，runtime如何实现weak变量的自动置nil？

	runtime 对注册的类， 会进行布局，对于 weak 对象会放入一个 hash 表中。 

	用 weak 指向的对象内存地址作为 key，当此对象的引用计数为0的时候会 dealloc，

	假如 weak 指向的对象内存地址是a，那么就会以a为键， 在这个 weak 表中搜索，找到所有以a为键的 weak 对象，从而设置为 nil。

6，能否向编译后得到的类中增加实例变量？能否向运行时创建的类中添加实例变量？为什么？

	不能向编译后得到的类中增加实例变量；
	
	能向运行时创建的类中添加实例变量；

	因为编译后的类已经注册在 runtime 中，类结构体中的 objc_ivar_list 实例变量的链表 和 instance_size 实例变量的内存大小已经确定，

	同时runtime 会调用 class_setIvarLayout 或 class_setWeakIvarLayout 来处理 strong weak 引用。所以不能向存在的类中添加实例变量；

	运行时创建的类是可以添加实例变量，调用 class_addIvar 函数。但是得在调用 objc_allocateClassPair 之后，objc_registerClassPair 之前，原因同上。

在block内如何修改block外部变量？
	
	 默认情况下，在block中访问的外部变量是复制过去的，即：写操作不对原变量生效。但是你可以加上 __block 来让其写操作生效

	 Block不允许修改外部变量的值，这里所说的外部变量的值，指的是栈中指针的内存地址。__block 所起到的作用就是只要观察到该变量被 block 所持有，

	 就将“外部变量”在栈中的内存地址放到了堆中。进而在block内部也可以修改外部变量的值

7， NSCache 与 NSMutableDictionary 等集合类的区别或者说优势又是哪些呢？

	NSCache 类结合了各种自动删除策略，以确保不会占用过多的系统内存。如果其它应用需要内存时，系统自动执行这些策略。当调用这些策略时，会从缓存中删除一些对象，以最大限度减少内存的占用

	NSCache 是线程安全的，我们可以在不同的线程中添加、删除和查询缓存中的对象，而不需要锁定缓存区域

	不像 NSMutableDictionary 对象，NSCache 对象并不会拷贝键（key），而是会强引用它


/************************************ RunLoop *************************************************/
RunLoop ：
	
	RunLoop 实际上就是一个对象，这个对象管理了其需要处理的事件和消息，并提供了一个入口函数来执行循环事件的逻辑。

	线程执行了这个函数后，就会一直处于这个函数内部 "接受消息->等待->处理" 的循环中，直到这个循环结束（比如传入 quit 的消息），函数返回。

	OSX/iOS 系统中，提供了两个这样的对象：NSRunLoop 和 CFRunLoopRef

		CFRunLoopRef 是在 CoreFoundation 框架内的，它提供了纯 C 函数的 API，所有这些 API 都是线程安全的。

		NSRunLoop 是基于 CFRunLoopRef 的封装，提供了面向对象的 API，但是这些 API 不是线程安全的。

	RunLoop 与线程的关系：

		苹果不允许直接创建 RunLoop，它只提供了两个自动获取的函数：CFRunLoopGetMain() 和 CFRunLoopGetCurrent()

		主线程的runloop 默认是启动的；对于其他线程来说runloop 默认是没有启动的
		
		线程和 RunLoop 之间是一一对应的，其关系是保存在一个全局的 Dictionary 里。线程刚创建时并没有 RunLoop，如果你不主动获取，那它一直都不会有。

		RunLoop 的创建是发生在第一次获取时，RunLoop 的销毁是发生在线程结束时。你只能在一个线程的内部获取其 RunLoop（主线程除外）。

	CoreFoundation 里面关于 RunLoop 有5个类:
		
		CFRunLoopRef //就是RunLoop，提供CFRunLoopGetMain()和CFRunLoopGetCurrent()
		
		CFRunLoopModeRef //RunLoop运行模式
		
		CFRunLoopSourceRef //RunLoop里面内容 -- 事件源，输入源
		
		CFRunLoopTimerRef //RunLoop里面内容 -- 定时器
		
		CFRunLoopObserverRef //RunLoop里面内容 -- 观察者

		一个RunLoop里面可以有多个mode，每个mode又可以多个source，observer，timer。**可是每次RunLoop只能指定一个mode运行，如果想要切换mode，就必须先退出RunLoop

		，然后重新指定mode运行，这样做的目的就是避免mode之间相互影响

	RunLoop 的 mode 作用是什么？model 主要是用来指定事件在运行循环中的优先级

		分为：
			NSDefaultRunLoopMode（kCFRunLoopDefaultMode）：默认，空闲状态
			
			UITrackingRunLoopMode：ScrollView滑动时
			
			UIInitializationRunLoopMode：启动时
			
			NSRunLoopCommonModes（kCFRunLoopCommonModes）：Mode集合

		苹果公开提供的 Mode 有两个：

			NSDefaultRunLoopMode（kCFRunLoopDefaultMode）
			
			NSRunLoopCommonModes（kCFRunLoopCommonModes）

	以+ scheduledTimerWithTimeInterval...的方式触发的timer，在滑动页面上的列表时，timer会暂定回调，为什么？如何解决？

		RunLoop只能运行在一种mode下，如果要换mode，当前的loop也需要停下重启成新的。利用这个机制，

		ScrollView滚动过程中NSDefaultRunLoopMode（kCFRunLoopDefaultMode）的mode会切换到UITrackingRunLoopMode来保证ScrollView的流畅滑动：

		只能在NSDefaultRunLoopMode模式下处理的事件会影响ScrollView的滑动。如果我们把一个NSTimer对象以NSDefaultRunLoopMode（kCFRunLoopDefaultMode）

		添加到主运行循环中的时候, ScrollView滚动过程中会因为mode的切换，而导致NSTimer将不再被调度。

		解决方案：

			mode还是可定制的，所以：

			Timer计时会被scrollView的滑动影响的问题可以通过将timer添加到NSRunLoopCommonModes（kCFRunLoopCommonModes）来解决

	猜想runloop内部是如何实现的？

		一般来讲，一个线程一次只能执行一个任务，执行完成后线程就会退出。如果我们需要一个机制，让线程能随时处理事件但并不退出，通常的代码逻辑 是这样的：

		使用伪代码来展示下:

			// 
			// http://weibo.com/luohanchenyilong/ (微博@iOS程序犭袁)
			// https://github.com/ChenYilong
			
			int main(int argc, char * argv[]) {
			
			 //程序一直运行状态
			 while (AppIsRunning) {
			
			      //睡眠状态，等待唤醒事件
			      id whoWakesMe = SleepForWakingUp();
			
			      //得到唤醒事件
			      id event = GetEvent(whoWakesMe);
			
			      //开始处理事件
			      HandleEvent(event);
			
			 }
			
			 return 0;
			}



/************************************ UIApplication生命周期 *************************************************/

UIApplication生命周期的一些delegate方法:

	程序启动过程相关的一些delegate方法的调用时机如下：

		- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
		  
		  NSLog(@"程序启动完成：%s",__func__);
		  
		  return YES;
		}
		 
		- (void)applicationDidBecomeActive:(UIApplication *)application {
		  
		    NSLog(@"已经获得焦点：%s",__func__);
		}
		 
		- (void)applicationWillResignActive:(UIApplication *)application {
		  
		    NSLog(@"将要释放焦点：%s",__func__);
		}
		 
		- (void)applicationDidEnterBackground:(UIApplication *)application {
		  
		    NSLog(@"已经进入后台：%s",__func__);
		}
		 
		- (void)applicationWillEnterForeground:(UIApplication *)application {
		  
		    NSLog(@"将要进入前台：%s",__func__);
		}
		 
		- (void)applicationWillTerminate:(UIApplication *)application {
		  
		    NSLog(@"程序将要退出：%s",__func__);
		}

	情景1：程序启动：

		程序被加载到内存，完成启动，application对象会自动调用delegate的这个方法 didFinishLaunchingWithOptions:，证明程序已经启动完成。

		所以这个方法也是首先会被application回调的方法，且这个方法在整个程序的生命周期中只会被调用一次；该方法完成之后会调用 applicationDidBecomeActive：证明程序已经获得了焦点

		应用启动过程中，会依次调用delegate已经启动完成和已经获得焦点的方法，不会调用已经进入前台的方法。

	情景2：程序从前台退出后台：

		当程序处于前台时,单击home键，程序会自动退出到后台。在这个过程中，程序会先回调delegate的将要失去焦点的方法，证明程序将要失去焦点。

		- (void)applicationWillResignActive:(UIApplication *)application;

		调用调用完上面的方法后，程序紧接着会调用delegate已经进入后台的方法，证明程序已经进入后台。

		- (void)applicationDidEnterBackground:(UIApplication *)application;

		结论：单击home键进入后台会依次调用delegate的将要失去焦点的方法和已经进入后台的方法。

	情景3：程序从后台进入到前台

		从后台进入前台(无论是双击home键进入或者点击应用图标进入)，会回调delegate的将要进入前台方法，证明程序将要进入前台。

		- (void)applicationWillEnterForeground:(UIApplication *)application;

		回调完上面的方法，紧接着会继续回调delegate的已经获得焦点的方法，证明程序已经获得了焦点。

		- (void)applicationDidBecomeActive:(UIApplication *)application；

		结论：从后台进入前台，会依次调用delegate的将要进入前台和已经获得焦点的方法。

	情景4：双击home键切换程序

		在前台，双击home键，只会调用delegate的将要失去焦点的方法，证明程序将要失去焦点。

		- (void)applicationWillResignActive:(UIApplication *)application;

		当用户真正切换应用时候，才会继续调用delegate的已经进入后台的方法，证明程序已经进入后台。

		- (void)applicationDidEnterBackground:(UIApplication *)application;

		结论：双击home键切换应用。会分别调用程序将要失去焦点的方法和程序已经进入后台的方法。 且这两个方法是分开调用的。

		即，双击home键时调用将要失去焦点的方法，选择其他应用时调用已经进入后台的方法。

	情景5：在前台双击home键杀死程序

		双击home键时，只会调用delegate的将要失去焦点的方法（上面已经说过）,证明程序将要失去焦点。

		- (void)applicationWillResignActive:(UIApplication *)application;

		然后手指上滑杀死程序，会直接调用delegate的已经进入后台的方法，证明程序已经进入后台。

		- (void)applicationDidEnterBackground:(UIApplication *)application;

		然后紧接着调用delegate的程序将要退出的方法，证明程序将要被杀死。
		
		-(void)applicationWillTerminate:(UIApplication *)application;

	情景6：从其他程序前台双击home键杀死后台程序

		如果从其他程序的前台，双击home键杀死后台程序，被杀死程序只会回调delegate即将退出的方法。

		因为我们是从一个前台程序杀死一个后台程序，这个后台程序当初进入后台时候已经调用了将要释放焦点和已经进入后台的方法，

		所以杀死时候只会回调delegate即将终结的方法。

	情景7：下拉通知栏

		下拉通知栏，只会回调delegate的程序将要释放焦点的方法。程序并没有进入后台，所以不会调用进入后台的方法

		因为下拉通知栏只调用了将要释放焦点的方法，没有调用进入后台方法，所以收起通知栏时，只会调用已经获得焦点的方法，不会调用进入前台的方法。

		同样，从屏幕下方向上滑动屏幕，唤出工具栏时候，也只会调用delegate的将要释放焦点的方法。收起工具栏时，只会调用delegate的已经获得焦点的方法。

	
		注：如果一个应用程序失去焦点那么意味着用户当前无法进行交互操作，正因如此，程序从前台退出到后台时候，
			
			一般会先失去焦点再进入后台避免进入后台过程中用户还可以和程序进行交互。同理，一个应用程序从后台进入前台也是类似的，

			会先进入前台再获得焦点，这样进入前台过程中未完全准备好的情况下用户无法操作，保证了程序的安全性。


/************************************************ KVO KVC *******************************************/

    KVC :  Key-value coding 运用了一个isa-swizzling技术，它提供了一种使用字符串而不是访问器方法去访问一个对象实例变量的机制。

        isa-swizzling就是类型混合指针机制。KVC主要通过isa-swizzling，来实现其内部查找定位的；

        最要方法：

            - (id)valueForKey:(NSString *)key;

            - (void)setValue:(id)value forKey:(NSString *)key;

            - (id)valueForKeyPath:(NSString *)keyPath;

            -  (void)setValue:(id)value forKeyPath:(NSString *)keyPath;

            前边两个方法用到的Key较容易理解，就是要访问的属性名称对应的字符串。

            后面两个方法用到的KeyPath是一个被点操作符隔开的用于访问对象的指定属性的字符串序列

        实现原理：KVC再某种程度上提供了访问器的替代方案。不过访问器方法是一个很好的东西，以至于只要是有可能，
                
                KVC也尽量在访问器方法的帮助下工作。为了设置或者返回对象属性，KVC按顺序使用如下技术：
                
                ①检查是否存在-<key>、-is<key>（只针对布尔值有效）或者-get<key>的访问器方法，如果有可能，就是用这些方法返回值；
                
                    检查是否存在名为-set<key>:的方法，并使用它做设置值。对于-get<key>和-set<key>:方法，将大写Key字符串的第一个字母，并与Cocoa的方法命名保持一致；
                
                ②如果上述方法不可用，则检查名为-_<key>、-_is<key>（只针对布尔值有效）、-_get<key>和-_set<key>:方法；
                
                ③如果没有找到访问器方法，可以尝试直接访问实例变量。实例变量可以是名为：<key>或_<key>;
                
                ④如果仍为找到，则调用valueForUndefinedKey:和setValue:forUndefinedKey:方法。这些方法的默认实现都是抛出异常，我们可以根据需要重写它们。

    KVO : Key-value observing 翻译成键值观察。提供了一种当其它对象属性被修改的时候能通知当前对象的机制

        实现原理：当某个类的对象第一次被观察时，系统就会在运行期动态地创建该类的一个派生类，在这个派生类中重写基类中任何被观察属性的 setter 方法。派生类在被重写的 setter 方法实现真正的通知机制

        如果之前的类名为：Person，那么被runtime更改以后的类名会变成：NSKVONotifying_Person。新的NSKVONotifying_Person类会重写以下方法：增加了监听的属性对应的set方法，class，dealloc，_isKVOA

            ①class
            
                重写class方法是为了我们调用它的时候返回跟重写继承类之前同样的内容
            
            ②重写set方法新类会重写对应的set方法，是为了在set方法中增加另外两个方法的调用：- (void)willChangeValueForKey:(NSString *)key 或者 - (void)didChangeValueForKey:(NSString *)key,  其中，didChangeValueForKey:方法负责调用：- (void)observeValueForKeyPath: ofObject: change: context:这就是KVO实现的原理了！

总结一下，想使用KVO有三种方法：
    
    1)使用了KVC
    
        使用了KVC，如果有访问器方法，则运行时会在访问器方法中调用will/didChangeValueForKey:方法；
    
        没用访问器方法，运行时会在setValue:forKey方法中调用will/didChangeValueForKey:方法。
    
    2)有访问器方法
    
        运行时会重写访问器方法调用will/didChangeValueForKey:方法。
    
        因此，直接调用访问器方法改变属性值时，KVO也能监听到。
    
    3)显示调用will/didChangeValueForKey:方法。

如何手动触发一个value的KVO？
	
	自动触发 KVO 的原理：

		键值观察通知依赖于 NSObject 的两个方法: willChangeValueForKey: 和 didChangevlueForKey: 。

		在一个被观察属性发生改变之前， willChangeValueForKey: 一定会被调用，这就 会记录旧的值。

		而当改变发生后， observeValueForKey:ofObject:change:context: 会被调用，继而 didChangeValueForKey: 也会被调用。

		如果可以手动实现这些调用，就可以实现“手动触发”了。

/************************************************ UITableView复用 ***************************************/

// 返回第section组有多少行
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{}

// 返回每一行cell的样子
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{}

// 返回每行cell的高度
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{}

分析：系统会先调用numberOfSections获取每个section中有多少个cell；再获取每个cell的高度，计算所有cell的frame,就能计算下tableView的滚动范围；然后循环调用cellForRow和heightForRow，直到cell的个数充满当前屏幕。
    tableView:cellForRowAtIndexPath:方法调用的次数，取决于当前屏幕显示cell的个数，一开始只加载显示出来的cell，等有新的cell出现的时候会继续调用这个方法加载cell
    当新的cell出现的时候，首先从缓存池中获取，如果没有获取到，就自己创建cell。
    当有cell移除屏幕的时候，把cell放到缓存池中去。


/************************************* NSOperationQueue ************************************************/

NSOperation 和 GCD：其中 GCD 是基于 C 的底层的 API ，而 NSOperation 是对队列模型的高层级抽象，而且是基于GCD创建的。 

	虽然 NSOperation 是基于 GCD 实现的， 但是并不意味着它是一个 GCD 的 “dumbed-down” 版本， 

	相反，我们可以用NSOperation 轻易的实现一些 GCD 要写大量代码的事情。 因此， NSOperationQueue 是被推荐使用的， 

	除非你遇到了 NSOperationQueue 不能实现的问题。

	以下是 Operation Queues 和 Dispatch Queues 的不同：
		
		不遵循 FIFO（先进先出）：在 Operation Queues 中，你可以设置 operation（操作）的执行优先级，并且可以在 operation 之间添加依赖，这意味着你可以定义某些 operation，使得它们可以在另外一些 operation 执行完毕之后再被执行。这就是为什么它们不遵循先进先出的顺序。
		
		默认情况下 Operation Queues 是并发执行：虽然你不能将其改成串行队列，但还是有一种方法，通过在 operation 之间添加相依性来让 Operation Queues 中的任务按序执行。
		
		Operation Queues 是 NSOperationQueue 类的实例，任务被封装在 NSOperation 的实例中

	NSOperation:

		任务是以 NSOperation 实例的形式被提交到 Operation Queues 中去的。之前说过 GCD 中任务是以 block 的形式被提交
 
		NSOperation 是一个抽象类，不能直接使用，可以用他的子类 ：NSBlockOperation 和 NSInvocationOperation

			1，NSBlockOperation - 用这个类来初始化包含一个或多个 blocks 的 operation。该 operation 本身可包含的 block 超过一个，当所有的block 执行完毕后这个 operation 就被视为已完成。
			
			2，NSInvocationOperation - 用这个类来初始化一个 operation，能用来调用某指定对象的选择器（selector）

	优势:
		首先它可以通过 NSOperation 类的 addDependency（op: NSOperation）方法获得对相依性的支持

		可以设置 queuePriority 属性来改变执行的优先级

		可以取消掉某特定队列中的某个 operation，或者是取消队列中所有的 operation

			取消任何 operation 的时候，会是下面三种场景之一：
			
				你的 operation 已经完成了，这种情况下 cancel 方法没有任何效果。
			
				你的 operation 正在被执行的过程中，这种情况下系统不会强制停止你的 operation 代码，而是将 cancelled 属性置为 true。
			
				你的 operation 还在队列中等待被执行，这种情况下你的 operation 就不会被执行。

	NSOperation 有3个有用的布尔型属性：finished，cancelled 和 ready。

			finished 在 operation 执行完毕后被置为 true。
			
			cancelled 在 operation 被取消后被置为 true。

			ready 在 operation 即将被执行时被置为 true。

	所有的 NSOperation 在任务被完成后都可以选择去设置一段 completion block。NSOperation 的 finished 属性变为 true 后这段 block 就会被执行。

	例：

		var queue = NSOperationQueue()

		queue.addOperationWithBlock { () -> Void in
        
			//do something

		        NSOperationQueue.mainQueue().addOperationWithBlock({
		            
		            // configUI
		        })
		    }

		queue.addOperationWithBlock { () -> Void in

		        //do something
		        
		        NSOperationQueue.mainQueue().addOperationWithBlock({
		             
		             // configUI
		        })
		 
		    }

	或者：
		queue = NSOperationQueue()
		 
		let operation1 = NSBlockOperation(block: {
		
		let img1 = Downloader.downloadImageWithURL(imageURLs[0])
		
		NSOperationQueue.mainQueue().addOperationWithBlock({
			self.imageView1.image = img1
		        })
		    })
		    
		    operation1.completionBlock = {
		        print("Operation 1 completed")
		    }
		
		queue.addOperation(operation1)

