using Godot;
using System;

namespace Luny.Godot
{
    /// <summary>
    /// Ultra-thin Godot adapter: auto-initializes and forwards lifecycle to EngineLifecycleDispatcher.
    /// </summary>
    internal sealed partial class GodotLifecycleAdapter : Node
    {
        private static GodotLifecycleAdapter _instance;

        private IEngineLifecycleDispatcher _dispatcher;

        private GodotLifecycleAdapter()
        {
            GD.Print($"GodotLifecycleAdapter ({GetInstanceId()}) ctor");
            if (_instance != null)
            {
                EngineLifecycleDispatcher.ThrowDuplicateAdapterException(nameof(GodotLifecycleAdapter),
                    _instance.Name, unchecked((Int64)_instance.GetInstanceId()), Name, unchecked((Int64)GetInstanceId()));
            }

            _instance = this;
        }

        public override void _Ready()
        {
            GD.Print($"GodotLifecycleAdapter ({GetInstanceId()}) _Ready");
            _dispatcher = EngineLifecycleDispatcher.Instance;
        }

        public override void _EnterTree() => GD.Print($"GodotLifecycleAdapter ({GetInstanceId()}) _EnterTree");

        public override void _ExitTree()
        {
            GD.Print($"GodotLifecycleAdapter ({GetInstanceId()}) _ExitTree");
            if (_instance != null)
            {
                Shutdown();
                EngineLifecycleDispatcher.ThrowAdapterPrematurelyRemovedException(nameof(GodotLifecycleAdapter));
            }
        }

        public override void _Process(Double delta) => _dispatcher?.OnUpdate(delta);

        public override void _PhysicsProcess(Double delta) => _dispatcher?.OnFixedStep(delta);

        public override void _Notification(Int32 what)
        {
            if (what != NotificationProcess && what != NotificationPhysicsProcess)
                GD.Print($"GodotLifecycleAdapter ({GetInstanceId()}) what={what}");

            switch ((Int64)what)
            {
                case NotificationWMCloseRequest:
                    GD.Print($"GodotLifecycleAdapter ({GetInstanceId()}) NotificationWMCloseRequest");
                    Shutdown();
                    break;

                case NotificationCrash:
                    GD.Print($"GodotLifecycleAdapter ({GetInstanceId()}) NotificationCrash");
                    Shutdown();
                    break;
            }
        }

        private void Shutdown()
        {
            if (_instance != null)
            {
                _dispatcher?.OnShutdown();
                _dispatcher = null;
                _instance = null;
            }
        }
    }
}
